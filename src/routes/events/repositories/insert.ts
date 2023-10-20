import { database } from '../../../lib/database';
import type { Payload } from '../interfaces/aws-payload.interface';
import type { EventTypes } from '../interfaces/email';

interface InsertPayload {
  createdAt: string;
  payload: Payload;
  type: EventTypes;
}

export const insert = async (payload: InsertPayload) => {
  const INSERT_QUERY = {
    text: 'INSERT INTO email_events (created_at, aws_raw_payload, aws_message_id, type) VALUES ($1, $2, $3, $4)',
    values: [
      payload.createdAt,
      JSON.stringify(payload.payload),
      payload.payload.mail.messageId,
      payload.type,
    ],
  };

  const { rows: data } = await database.query(INSERT_QUERY);
  return data;
};
