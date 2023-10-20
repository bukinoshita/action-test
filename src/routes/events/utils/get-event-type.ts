import type { EventTypes } from '../interfaces/email';

export const getEventType = (eventType: string): EventTypes => {
  switch (eventType) {
    case 'Delivery':
      return 'delivered';
    case 'Open':
      return 'opened';
    case 'Click':
      return 'clicked';
    case 'Bounce':
      return 'bounced';
    case 'Complaint':
      return 'complained';
    default:
    case 'Send':
      return 'sent';
  }
};
