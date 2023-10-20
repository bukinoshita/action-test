import type { Request } from 'express';
import { randomUUID } from 'node:crypto';
import pinoHttp from 'pino-http';
import { logger } from '../lib/logger';

export const loggerInterceptor = pinoHttp({
  logger,
  genReqId: (req, res) => {
    const existingId = req.id ?? req.headers['x-request-id'];
    if (existingId) {
      return existingId;
    }

    const id = randomUUID();
    res.setHeader('X-Request-Id', id);
    return id;
  },
  customSuccessObject: (req, _res, val) => {
    return {
      ...val,
      req: {
        ...req,
        headers: req.headers,
      },
    };
  },
  customErrorObject: (req, _res, val) => {
    return {
      ...val,
      req: {
        ...req,
        headers: req.headers,
      },
    };
  },
  customSuccessMessage: (req: Request) => {
    return `${req.method} ${req.path} completed`;
  },
  customLogLevel: (_, res, err) => {
    if (res.statusCode >= 400 && res.statusCode < 500) {
      return 'warn';
    } else if (res.statusCode >= 500 || err) {
      return 'error';
    } else if (res.statusCode >= 300 && res.statusCode < 400) {
      return 'silent';
    }

    return 'info';
  },
});
