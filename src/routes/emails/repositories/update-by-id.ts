import { database } from '../../../lib/database';
import type { Email, EventTypes } from '../../events/interfaces/email';

interface UpdatePayload {
  lastEvent: EventTypes;
  awsMessageId: string;
}

export const updateById = async (
  id: string,
  payload: UpdatePayload,
): Promise<Email> => {
  const { rows: data } = await database.query(
    payload.lastEvent === 'sent'
      ? {
          text: `UPDATE emails SET last_event = $1, aws_message_id = $2 WHERE id = $3 AND (last_event IS NULL OR last_event = 'queued') RETURNING id, team_id, created_at, "from", "to", subject`,
          values: [payload.lastEvent, payload.awsMessageId, id],
        }
      : {
          text: `UPDATE emails SET last_event = $1, aws_message_id = $2 WHERE id = $3 RETURNING id, team_id, created_at, "from", "to", subject`,
          values: [payload.lastEvent, payload.awsMessageId, id],
        },
  );

  return data[0];
};
