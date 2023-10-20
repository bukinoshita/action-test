import type {
  BounceSubType,
  BounceType,
} from '../interfaces/aws-payload.interface';

export const getBounceMessage = (
  bounceType?: BounceType,
  bounceSubType?: BounceSubType,
) => {
  if (bounceType === 'Permanent' && bounceSubType === 'General') {
    return "The recipient's email provider sent a hard bounce message, but didn't specify the reason for the hard bounce. We recommend removing the recipient's email address from your mailing list. Sending messages to addresses that produce hard bounces can have a negative impact on your reputation as a sender.";
  }

  if (bounceType === 'Permanent' && bounceSubType === 'NoEmail') {
    return "The intended recipient's email provider sent a bounce message indicating that the email address doesn't exist. We recommend removing the recipient's email address from your mailing list. Sending messages to addresses that produce hard bounces can have a negative impact on your reputation as a sender.";
  }

  if (bounceType === 'Permanent' && bounceSubType === 'Suppressed') {
    return "The recipient's email address is on the suppression list because it has a recent history of producing hard bounces.";
  }

  if (
    bounceType === 'Permanent' &&
    bounceSubType === 'OnAccountSuppressionList'
  ) {
    return 'Resend has suppressed sending to this address because it is on the account-level suppression list. This does not count toward your bounce rate metric';
  }

  if (bounceType === 'Transient' && bounceSubType === 'General') {
    return "The recipient's email provider sent a general bounce message. You might be able to send a message to the same recipient in the future if the issue that caused the message to bounce is resolved.";
  }

  if (bounceType === 'Transient' && bounceSubType === 'MailboxFull') {
    return "The recipient's email provider sent a bounce message because the recipient's inbox was full. You might be able to send to the same recipient in the future when the mailbox is no longer full.";
  }

  if (bounceType === 'Transient' && bounceSubType === 'MessageTooLarge') {
    return "The recipient's email provider sent a bounce message because message you sent was too large. You might be able to send a message to the same recipient if you reduce the size of the message.";
  }

  if (bounceType === 'Transient' && bounceSubType === 'ContentRejected') {
    return "The recipient's email provider sent a bounce message because the message you sent contains content that the provider doesn't allow. You might be able to send a message to the same recipient if you change the content of the message.";
  }

  if (bounceType === 'Transient' && bounceSubType === 'AttachmentRejected') {
    return "The recipient's email provider sent a bounce message because the message contained an unacceptable attachment. For example, some email providers may reject messages with attachments of a certain file type, or messages with very large attachments. You might be able to send a message to the same recipient if you remove or change the content of the attachment.";
  }

  return "The recipient's email provider sent a bounce message. The bounce message didn't contain enough information for Resend to determine the reason for the bounce. The bounce email, which was sent to the address in the Return-Path header of the email that resulted in the bounce, might contain additional information about the issue that caused the email to bounce.";
};
