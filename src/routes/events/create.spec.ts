import request from 'supertest';
import app from '../../main';
import { randomUUID } from 'node:crypto';
import { database } from '../../lib/database';
import { inngest } from '../../lib/inngest';

const testTeamId = '5d1e4f6b-0868-488b-9145-d12723e3e2c2';

describe('POST /events', () => {
  test('returns 200 when event is created using `ses_email_id`', async () => {
    const sesEmailId = randomUUID();
    const awsMessageId = randomUUID();
    const { rows } = await database.query({
      text: 'INSERT INTO emails (id, team_id, "to", "from", subject, last_event) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      values: [
        sesEmailId,
        testTeamId,
        ['test@email.com'],
        'resend@resend.dev',
        'testing',
        'queued',
      ],
    });

    const response = await request(app)
      .post('/event')
      .send({
        eventType: 'Send',
        mail: {
          messageId: awsMessageId,
          timestamp: new Date().toISOString(),
          tags: { ses_email_id: [sesEmailId] },
        },
      });

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      event: expect.objectContaining({
        id: rows[0].id,
      }),
    });
  });

  test('updates an existing email status to `delivered`', async () => {
    const sesEmailId = randomUUID();
    const awsMessageId = randomUUID();

    const { rows } = await database.query({
      text: 'INSERT INTO emails (id, team_id, last_event, "to", "from", subject, aws_message_id) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      values: [
        sesEmailId,
        testTeamId,
        'send',
        ['test@email.com'],
        'resend@resend.dev',
        'testing',
        awsMessageId,
      ],
    });

    const response = await request(app)
      .post('/event')
      .send({
        eventType: 'Delivery',
        mail: {
          messageId: awsMessageId,
          timestamp: new Date().toISOString(),
        },
      });

    const { rows: createdEvents } = await database.query({
      text: 'SELECT id FROM email_events WHERE aws_message_id = $1 AND type = $2',
      values: [awsMessageId, 'delivered'],
    });

    expect(createdEvents.length).toBe(1);
    expect(response.status).toBe(200);

    expect(response.body).toEqual({
      event: expect.objectContaining({
        id: rows[0].id,
      }),
    });
  });

  test('calls `inngest.send` with the correct palyoad', async () => {
    const spy = vi.spyOn(inngest, 'send');

    const sesEmailId = randomUUID();
    const awsMessageId = randomUUID();

    const { rows } = await database.query({
      text: 'INSERT INTO emails (id, team_id, last_event, "to", "from", subject, aws_message_id) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      values: [
        sesEmailId,
        testTeamId,
        'send',
        ['test@email.com'],
        'resend@resend.dev',
        'subject test',
        awsMessageId,
      ],
    });

    const createdAt = new Date().toISOString();
    const response = await request(app)
      .post('/event')
      .send({
        eventType: 'Delivery',
        mail: {
          messageId: awsMessageId,
          timestamp: createdAt,
        },
      });

    expect(response.status).toBe(200);
    expect(spy).toHaveBeenCalledWith({
      name: 'webhooks/email-event.send',
      data: {
        teamId: testTeamId,
        type: 'delivered',
        createdAt,
        tags: undefined,
        bounceMessage:
          "The recipient's email provider sent a bounce message. The bounce message didn't contain enough information for Resend to determine the reason for the bounce. The bounce email, which was sent to the address in the Return-Path header of the email that resulted in the bounce, might contain additional information about the issue that caused the email to bounce.",
        click: {
          ipAddress: undefined,
          link: undefined,
          timestamp: undefined,
          userAgent: undefined,
        },
        payloadData: {
          emailId: rows[0].id,
          createdAt: rows[0].created_at,
          from: rows[0].from,
          to: rows[0].to,
          subject: rows[0].subject,
          headers: rows[0].headers,
        },
      },
    });
  });
});
