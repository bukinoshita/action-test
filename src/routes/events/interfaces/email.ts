export type EventTypes =
  | 'delivered'
  | 'opened'
  | 'clicked'
  | 'bounced'
  | 'sent'
  | 'complained';

export interface Email {
  id: string;
  team_id: string;
  created_at: string;
  from: string;
  to: string[];
  subject: string;
}
