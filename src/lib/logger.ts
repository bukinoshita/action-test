import pino from 'pino';

const transport = ['production', 'staging'].includes(process.env.NODE_ENV)
  ? {
      target: 'pino-logdna',
      options: {
        key: process.env.LOGGER_API_KEY,
        app: 'Resend Email Events',
        level: 'debug',
        indexMeta: true,
        env: process.env.NODE_ENV,
        timeout: 10000,
      },
    }
  : {
      target: 'pino-pretty',
      options: { singleLine: true },
    };

export const logger = pino({
  redact: ['req.headers.authorization'],
  transport,
});
