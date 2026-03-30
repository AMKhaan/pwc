/**
 * TypeORM CLI DataSource — used for generating and running migrations.
 * NOT used by the application at runtime (AppModule handles that).
 *
 * Usage:
 *   npm run migration:generate -- src/database/migrations/MigrationName
 *   npm run migration:run
 *   npm run migration:revert
 */

import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: ['src/database/entities/*.entity.ts'],
  migrations: ['src/database/migrations/*.ts'],
  synchronize: false,
  logging: true,
});
