// Run once to seed university domains:
// npx ts-node src/database/seeds/university-domains.seed.ts

import { DataSource } from 'typeorm';
import { UniversityDomain } from '../entities/university-domain.entity';
import * as dotenv from 'dotenv';
dotenv.config();

const universities = [
  { name: 'LUMS', domain: 'lums.edu.pk' },
  { name: 'FAST NUCES', domain: 'nu.edu.pk' },
  { name: 'UET Lahore', domain: 'uet.edu.pk' },
  { name: 'COMSATS Lahore', domain: 'comsats.edu.pk' },
  { name: 'University of Punjab', domain: 'pu.edu.pk' },
  { name: 'Beaconhouse National University', domain: 'bnu.edu.pk' },
  { name: 'LCWU', domain: 'lcwu.edu.pk' },
  { name: 'UMT Lahore', domain: 'umt.edu.pk' },
  { name: 'Superior University', domain: 'superior.edu.pk' },
  { name: 'GCU Lahore', domain: 'gcu.edu.pk' },
];

async function seed() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [UniversityDomain],
    synchronize: false,
  });

  await dataSource.initialize();
  const repo = dataSource.getRepository(UniversityDomain);

  for (const uni of universities) {
    const exists = await repo.findOne({ where: { domain: uni.domain } });
    if (!exists) {
      await repo.save(repo.create(uni));
      console.log(`Seeded: ${uni.name} (${uni.domain})`);
    } else {
      console.log(`Already exists: ${uni.domain}`);
    }
  }

  await dataSource.destroy();
  console.log('Seed complete.');
}

seed().catch(console.error);
