import * as Sentry from '@sentry/nestjs';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import * as express from 'express';
import * as path from 'path';
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';

// Initialize Sentry before anything else
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV || 'development',
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
  });
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ─── Raw body for file upload endpoint ─────────────────────────────────────
  // Must be registered BEFORE helmet/global middlewares so body-parser doesn't
  // consume the stream first. express.raw() makes req.body a Buffer.
  app.use(
    '/api/v1/storage/upload',
    express.raw({ type: '*/*', limit: '20mb' }),
  );

  // ─── Static file serving for uploaded files ────────────────────────────────
  const uploadsDir = process.env.UPLOADS_DIR ?? path.join(process.cwd(), 'uploads');
  app.use('/uploads', express.static(uploadsDir));

  // ─── Security ──────────────────────────────────────────────────────────────
  app.use(helmet());

  app.enableCors({
    origin: process.env.NODE_ENV === 'production'
      ? ['https://ridesync.pk', 'https://admin.ridesync.pk']
      : '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // ─── Global Pipes ──────────────────────────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,       // strip unknown fields
      forbidNonWhitelisted: true, // throw on unknown fields
      transform: true,       // auto-transform types
    }),
  );

  // ─── Global Filters ────────────────────────────────────────────────────────
  app.useGlobalFilters(new GlobalExceptionFilter());

  // ─── API Prefix ────────────────────────────────────────────────────────────
  app.setGlobalPrefix('api/v1');

  // ─── Swagger (dev only) ────────────────────────────────────────────────────
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('RideSync API')
      .setDescription('Professional ride sharing platform — Lahore, Pakistan')
      .setVersion('1.0')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
    console.log(`Swagger docs: http://localhost:${process.env.PORT || 3000}/api/docs`);
  }

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`RideSync API running on port ${port}`);
}

bootstrap();
