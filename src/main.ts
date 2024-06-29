import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const logger = new Logger('bootstrap');
  const app = await NestFactory.create(AppModule);
  if (process.env.NODE_ENV === 'development') {
    app.enableCors();
  } else {
    app.enableCors({ origin: "http://dmt-task-app.s3-website.eu-central-1.amazonaws.com" })
    logger.log(`Accepting requestes from origin http://dmt-task-app.s3-website.eu-central-1.amazonaws.com`)
  }
  const port = process.env.PORT || 3000
  await app.listen(port);
  logger.log(`Application listening on ${port}`);
}
bootstrap();
