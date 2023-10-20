import type { Application } from 'express';
import * as root from './root';
import * as emailEvents from './events';
import { loggerInterceptor } from '../middlewares/logger';

const routes = (app: Application) => {
  app.use(loggerInterceptor);

  app.get('/', root.get);

  // Email events
  app.post('/event', emailEvents.create);
  app.post('/events', emailEvents.create);
};

export default routes;
