import type { Request, Response } from 'express';
import type { Payload } from './interfaces/aws-payload.interface';
import { getEventType } from './utils/get-event-type';
import * as emails from '../emails/repositories';
import * as emailEvents from './';
import { getBounceMessage } from './utils/get-bounce-message';
import { inngest } from '../../lib/inngest';

export const create = async (req: Request, res: Response) => {
  try {
    const payload: Payload = req.body;
    const emailId = payload.mail?.tags?.ses_email_id?.[0] || null;
    const teamId = payload.mail?.tags?.ses_team_id?.[0] || null;
    const domainId = payload.mail?.tags?.ses_domain_id?.[0] || null;

    if (!emailId || !teamId || !domainId) {
      req.log.warn({ payload }, 'POST /event - Missing `ses` IDs');
    }

    const type = getEventType(payload.eventType);
    const eventTimestamp = getEventTimestamp(payload);
    const createdAt = eventTimestamp ?? payload.mail.timestamp;

    const updateProps = {
      awsMessageId: payload.mail.messageId,
      lastEvent: type,
    };
    const updateEmailPromise = emailId
      ? emails.repositories.updateById(emailId, updateProps)
      : emails.repositories.updateByAwsMessageId(
          payload.mail.messageId,
          updateProps,
        );

    const insertEventPromise = emailEvents.repositories.insert({
      createdAt,
      payload,
      type,
    });

    const [event] = await Promise.all([updateEmailPromise, insertEventPromise]);

    if (event) {
      const bounceMessage = getBounceMessage(
        payload?.bounce?.bounceType,
        payload?.bounce?.bounceSubType,
      );

      await inngest.send({
        name: 'webhooks/email-event.send',
        data: {
          teamId: event.team_id,
          tags: payload.mail.tags,
          type,
          createdAt,
          bounceMessage,
          click: {
            ipAddress: payload?.click?.ipAddress,
            link: payload?.click?.link,
            timestamp: payload?.click?.timestamp,
            userAgent: payload?.click?.userAgent,
          },
          payloadData: {
            emailId: emailId || event.id,
            createdAt: event.created_at,
            from: event.from,
            to: event.to,
            subject: event.subject,
            headers: payload.mail.headers,
          },
        },
      });
    }

    return res.status(200).json({ event });
  } catch (error) {
    req.log.error({ error }, 'POST /event');
    return res.status(500).json({ error });
  }
};

const getEventTimestamp = (payload: Payload): string | undefined => {
  const eventType = payload.eventType.toLowerCase();
  return payload[eventType]?.timestamp;
};
