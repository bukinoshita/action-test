import { database } from '../../../lib/database';
import type { Email, EventTypes } from '../../events/interfaces/email';

interface UpdatePayload {
  lastEvent: EventTypes;
}

export const updateByAwsMessageId = async (
  id: string,
  payload: UpdatePayload,
): Promise<Email> => {
  const { rows: data } = await database.query(
    payload.lastEvent === 'sent'
      ? {
          text: `UPDATE emails SET last_event = $1 WHERE aws_message_id = $2 AND last_event IS NULL RETURNING id, team_id, created_at, "from", "to", subject`,
          values: [payload.lastEvent, id],
        }
      : {
          text: `UPDATE emails SET last_event = $1 WHERE aws_message_id = $2 RETURNING id, team_id, created_at, "from", "to", subject`,
          values: [payload.lastEvent, id],
        },
  );

  return data[0];
};
