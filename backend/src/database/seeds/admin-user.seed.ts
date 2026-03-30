// Creates the first admin user
// Run: npx ts-node -r tsconfig-paths/register src/database/seeds/admin-user.seed.ts

import { DataSource } from 'typeorm';
import { User, UserType, VerificationStatus } from '../entities/user.entity';
import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
dotenv.config();

async function seed() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [User],
    synchronize: false,
  });

  await dataSource.initialize();
  const repo = dataSource.getRepository(User);

  const ADMIN_EMAIL = 'admin@ridesync.pk';
  const ADMIN_PASSWORD = 'Admin@12345';

  const exists = await repo.findOne({ where: { email: ADMIN_EMAIL } });
  if (exists) {
    console.log(`Admin already exists: ${ADMIN_EMAIL}`);
    await dataSource.destroy();
    return;
  }

  const hashed = await bcrypt.hash(ADMIN_PASSWORD, 12);
  const admin = repo.create({
    email: ADMIN_EMAIL,
    password: hashed,
    firstName: 'RideSync',
    lastName: 'Admin',
    userType: UserType.PROFESSIONAL,
    verificationStatus: VerificationStatus.VERIFIED,
    isEmailVerified: true,
    isAdmin: true,
    trustScore: 100,
  });

  await repo.save(admin);
  console.log(`\n✅ Admin user created`);
  console.log(`   Email:    ${ADMIN_EMAIL}`);
  console.log(`   Password: ${ADMIN_PASSWORD}`);
  console.log(`\n⚠️  Change the password immediately after first login!\n`);

  await dataSource.destroy();
}

seed().catch(console.error);
