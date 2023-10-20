import * as dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import routes from './routes';

const app = express();

app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ limit: '20mb', extended: true }));
app.disable('x-powered-by');

routes(app);

export default app;
