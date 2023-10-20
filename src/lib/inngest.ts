import { Inngest } from 'inngest';

export const inngest = new Inngest({
  name: 'resend',
  eventKey: process.env.INNGEST_EVENT_KEY,
});
