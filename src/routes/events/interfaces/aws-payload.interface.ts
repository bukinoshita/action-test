export interface Payload {
  eventType: 'Send' | 'Delivery';
  mail: {
    timestamp: string;
    source: string;
    sourceArn: string;
    sendingAccountId: string;
    messageId: string;
    destination: string[];
    headersTruncated: boolean;
    headers: {
      name: string;
      value: string;
    }[];
    commonHeaders: {
      bcc?: string[];
      cc?: string[];
      date?: string;
      from: string[];
      messageId: string;
      reply_to?: string[];
      returnPath?: string;
      subject: string;
      to: string[];
    };
    tags: {
      [key: string]: string[];
    };
  };
  click?: {
    ipAddress: string;
    link: string;
    timestamp: string;
    userAgent: string;
  };
  delivery?: {
    timestamp: string;
    processingTimeMillis: number;
    recipients: string[];
    smtpResponse: string;
    reportingMTA: string;
  };
  send?: object;
  bounce?: {
    feedbackId: string;
    bounceType: BounceType;
    bounceSubType: BounceSubType;
    bouncedRecipients?: [
      {
        emailAddress: string;
        action: string;
        status: string;
        diagnosticCode: string;
      },
    ];
    timestamp: string;
    reportingMTA: string;
  };
}

export type BounceSubType =
  | 'Undetermined'
  | 'General'
  | 'NoEmail'
  | 'Suppressed'
  | 'OnAccountSuppressionList'
  | 'MailboxFull'
  | 'MessageTooLarge'
  | 'ContentRejected'
  | 'AttachmentRejected';

export type BounceType = 'Undetermined' | 'Transient' | 'Permanent';
