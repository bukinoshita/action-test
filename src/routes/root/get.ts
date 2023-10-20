import type { Request, Response } from 'express';

export const get = async (_req: Request, res: Response) => {
  return res.status(200).json({ status: 'ok' });
};
