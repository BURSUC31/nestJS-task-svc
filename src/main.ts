import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';
import * as config from 'config';
import { ServerConfig } from 'config/config-types';

async function bootstrap() {
  const serverConfig = config.get('server') as ServerConfig;
  const logger = new Logger('bootstrap');
  const app = await NestFactory.create(AppModule);
  if (process.env.NODE_ENV === 'development') {
    app.enableCors();
  }
  const port = process.env.PORT || serverConfig.port;
  await app.listen(port);
  logger.log(`Application listening on ${port}`);
}
bootstrap();
