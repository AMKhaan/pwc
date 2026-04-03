// Seed 5 test users with vehicles and rides
// Run: npm run seed:test-users
//
// ⚠️  Deletes ALL non-admin users (and their rides/vehicles/bookings) first,
//     then creates 5 fresh test users. Safe to re-run on local or droplet.

import { DataSource } from 'typeorm';
import { User, UserType, VerificationStatus, Gender, GenderPreference } from '../entities/user.entity';
import { Vehicle, VehicleType, FuelType } from '../entities/vehicle.entity';
import { Ride, RideType, RideStatus } from '../entities/ride.entity';
import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
dotenv.config();

// ─── Locations (real coords) ──────────────────────────────────────────────────

const LOCATIONS = {
  dhaPhase5:     { address: 'DHA Phase 5, Lahore',             lat: 31.4712, lng: 74.4013 },
  dhaPhase6:     { address: 'DHA Phase 6, Lahore',             lat: 31.4550, lng: 74.4228 },
  dhaPhase1:     { address: 'DHA Phase 1, Lahore',             lat: 31.4916, lng: 74.3902 },
  gulberg3:      { address: 'Gulberg III, Lahore',             lat: 31.5001, lng: 74.3334 },
  gulberg2:      { address: 'Gulberg II, Lahore',              lat: 31.5098, lng: 74.3358 },
  modelTown:     { address: 'Model Town, Lahore',              lat: 31.4969, lng: 74.3151 },
  joharTown:     { address: 'Johar Town, Lahore',              lat: 31.4697, lng: 74.2748 },
  bahriaTown:    { address: 'Bahria Town, Lahore',             lat: 31.3661, lng: 74.2015 },
  cavalryGround: { address: 'Cavalry Ground, Lahore',          lat: 31.5172, lng: 74.3533 },
  libertyMarket: { address: 'Liberty Market, Gulberg, Lahore', lat: 31.5124, lng: 74.3371 },
  mmAlam:        { address: 'MM Alam Road, Gulberg, Lahore',   lat: 31.4998, lng: 74.3382 },
  mallRoad:      { address: 'Mall Road, Lahore',               lat: 31.5490, lng: 74.3282 },
  cantt:         { address: 'Lahore Cantt, Lahore',            lat: 31.5407, lng: 74.3213 },
  wapdaTown:     { address: 'Wapda Town, Lahore',              lat: 31.4530, lng: 74.2880 },
  emeSociety:    { address: 'EME Society, Lahore',             lat: 31.4632, lng: 74.2832 },
  township:      { address: 'Township, Lahore',                lat: 31.4742, lng: 74.2714 },
  thokarNiaz:    { address: 'Thokar Niaz Baig, Lahore',       lat: 31.4090, lng: 74.3104 },
  lums:          { address: 'LUMS, DHA, Lahore',               lat: 31.4715, lng: 74.4029 },
  fast:          { address: 'FAST NUCES, Faisal Town, Lahore', lat: 31.4819, lng: 74.4013 },
  uet:           { address: 'UET Lahore, Grand Trunk Road',    lat: 31.5153, lng: 74.3249 },
  gardenTown:    { address: 'Garden Town, Lahore',             lat: 31.5056, lng: 74.3207 },
  shadmanColony: { address: 'Shadman Colony, Lahore',          lat: 31.5263, lng: 74.3149 },
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function daysFromNow(days: number, hour: number, minute = 0): Date {
  const d = new Date();
  d.setDate(d.getDate() + days);
  d.setHours(hour, minute, 0, 0);
  return d;
}

function dist(o: { lat: number; lng: number }, d: { lat: number; lng: number }): number {
  const R = 6371;
  const dLat = ((d.lat - o.lat) * Math.PI) / 180;
  const dLng = ((d.lng - o.lng) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((o.lat * Math.PI) / 180) *
      Math.cos((d.lat * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
}

// ─── User definitions ─────────────────────────────────────────────────────────

const USERS = [
  {
    n: 1, firstName: 'Test', lastName: '1', gender: Gender.MALE, userType: UserType.PROFESSIONAL,
    jobTitle: 'Software Engineer', officeName: 'Systems Limited', cnicNumber: '3520112345671',
    phone: '03001000001',
    vehicle: { make: 'Toyota', model: 'Corolla', year: 2021, color: 'White',  plate: 'LHR-2021-AA', seats: 3, fuel: FuelType.PETROL, cc: 1800 },
  },
  {
    n: 2, firstName: 'Test', lastName: '2', gender: Gender.FEMALE, userType: UserType.PROFESSIONAL,
    jobTitle: 'Product Manager', officeName: 'Netsol Technologies', cnicNumber: '3520212345672',
    phone: '03001000002',
    vehicle: { make: 'Honda', model: 'Civic', year: 2022, color: 'Silver', plate: 'LHR-2022-BB', seats: 3, fuel: FuelType.PETROL, cc: 1500 },
  },
  {
    n: 3, firstName: 'Test', lastName: '3', gender: Gender.MALE, userType: UserType.PROFESSIONAL,
    jobTitle: 'Business Analyst', officeName: 'Arbisoft', cnicNumber: '3520312345673',
    phone: '03001000003',
    vehicle: { make: 'Suzuki', model: 'Cultus', year: 2020, color: 'Red', plate: 'LHR-2020-CC', seats: 3, fuel: FuelType.CNG, cc: 1000 },
  },
  {
    n: 4, firstName: 'Test', lastName: '4', gender: Gender.FEMALE, userType: UserType.STUDENT,
    degreeDesignation: 'BS Computer Science', universityName: 'LUMS', cnicNumber: '3520412345674',
    phone: '03001000004',
    vehicle: { make: 'Toyota', model: 'Yaris', year: 2023, color: 'Blue', plate: 'LHR-2023-DD', seats: 3, fuel: FuelType.PETROL, cc: 1300 },
  },
  {
    n: 5, firstName: 'Test', lastName: '5', gender: Gender.MALE, userType: UserType.PROFESSIONAL,
    jobTitle: 'DevOps Engineer', officeName: 'TRG Pakistan', cnicNumber: '3520512345675',
    phone: '03001000005',
    vehicle: { make: 'Honda', model: 'City', year: 2021, color: 'Black', plate: 'LHR-2021-EE', seats: 3, fuel: FuelType.PETROL, cc: 1200 },
  },
];

// ─── Rides per user ───────────────────────────────────────────────────────────

type Loc = typeof LOCATIONS[keyof typeof LOCATIONS];
const L = LOCATIONS;

const RIDES_PER_USER: Record<number, Array<{ rideType: RideType; origin: Loc; dest: Loc; daysAhead: number; hour: number; seats: number; price: number; notes?: string }>> = {
  1: [
    { rideType: RideType.OFFICE,     origin: L.dhaPhase5,     dest: L.gulberg3,      daysAhead: 1, hour: 8,  seats: 3, price: 150 },
    { rideType: RideType.OFFICE,     origin: L.dhaPhase5,     dest: L.mmAlam,        daysAhead: 2, hour: 8,  seats: 3, price: 150, notes: 'AC available' },
    { rideType: RideType.OFFICE,     origin: L.dhaPhase5,     dest: L.libertyMarket, daysAhead: 3, hour: 17, seats: 3, price: 150 },
    { rideType: RideType.OFFICE,     origin: L.dhaPhase6,     dest: L.gulberg2,      daysAhead: 4, hour: 8,  seats: 3, price: 200 },
  ],
  2: [
    { rideType: RideType.OFFICE,     origin: L.cavalryGround, dest: L.mallRoad,      daysAhead: 1, hour: 9,  seats: 3, price: 100 },
    { rideType: RideType.OFFICE,     origin: L.cavalryGround, dest: L.gardenTown,    daysAhead: 2, hour: 8,  seats: 3, price: 120, notes: 'Female preferred' },
    { rideType: RideType.OFFICE,     origin: L.gulberg2,      dest: L.cantt,         daysAhead: 3, hour: 18, seats: 3, price: 100 },
    { rideType: RideType.OFFICE,     origin: L.cavalryGround, dest: L.libertyMarket, daysAhead: 5, hour: 8,  seats: 3, price: 110 },
  ],
  3: [
    { rideType: RideType.OFFICE,     origin: L.joharTown,     dest: L.gulberg3,      daysAhead: 1, hour: 8,  seats: 3, price: 120 },
    { rideType: RideType.OFFICE,     origin: L.joharTown,     dest: L.modelTown,     daysAhead: 2, hour: 8,  seats: 3, price: 80  },
    { rideType: RideType.OFFICE,     origin: L.wapdaTown,     dest: L.gulberg3,      daysAhead: 3, hour: 9,  seats: 3, price: 130 },
    { rideType: RideType.OFFICE,     origin: L.joharTown,     dest: L.libertyMarket, daysAhead: 4, hour: 8,  seats: 3, price: 150, notes: 'CNG vehicle — cheap ride' },
  ],
  4: [
    { rideType: RideType.UNIVERSITY, origin: L.modelTown,     dest: L.lums,          daysAhead: 1, hour: 7,  seats: 3, price: 150 },
    { rideType: RideType.UNIVERSITY, origin: L.gulberg3,      dest: L.lums,          daysAhead: 2, hour: 7,  seats: 3, price: 120 },
    { rideType: RideType.UNIVERSITY, origin: L.modelTown,     dest: L.fast,          daysAhead: 3, hour: 7,  seats: 3, price: 130 },
    { rideType: RideType.UNIVERSITY, origin: L.gulberg2,      dest: L.lums,          daysAhead: 5, hour: 7,  seats: 3, price: 140, notes: 'Morning class schedule' },
  ],
  5: [
    { rideType: RideType.OFFICE,     origin: L.bahriaTown,    dest: L.gulberg3,      daysAhead: 1, hour: 8,  seats: 3, price: 250 },
    { rideType: RideType.OFFICE,     origin: L.bahriaTown,    dest: L.libertyMarket, daysAhead: 2, hour: 8,  seats: 3, price: 250 },
    { rideType: RideType.OFFICE,     origin: L.bahriaTown,    dest: L.mmAlam,        daysAhead: 3, hour: 8,  seats: 3, price: 250, notes: 'Daily 5 days a week' },
    { rideType: RideType.OFFICE,     origin: L.thokarNiaz,    dest: L.gulberg2,      daysAhead: 4, hour: 9,  seats: 3, price: 200 },
  ],
};

// ─── Main seed ────────────────────────────────────────────────────────────────

async function seed() {
  const dataSource = new DataSource({
    type: 'postgres',
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [User, Vehicle, Ride],
    synchronize: false,
  });

  await dataSource.initialize();
  const userRepo    = dataSource.getRepository(User);
  const vehicleRepo = dataSource.getRepository(Vehicle);
  const rideRepo    = dataSource.getRepository(Ride);

  // ── Step 1: wipe all non-admin users and their data ──────────────────────────
  console.log('\n🗑  Clearing non-admin users...');

  const nonAdminUsers = await userRepo
    .createQueryBuilder('u')
    .where('u.userType != :type', { type: 'ADMIN' })
    .getMany();

  if (nonAdminUsers.length > 0) {
    const ids = nonAdminUsers.map(u => u.id);

    // Delete in dependency order: rides → vehicles → users
    await rideRepo
      .createQueryBuilder()
      .delete()
      .where('driverId IN (:...ids)', { ids })
      .execute();

    await vehicleRepo
      .createQueryBuilder()
      .delete()
      .where('userId IN (:...ids)', { ids })
      .execute();

    await userRepo
      .createQueryBuilder()
      .delete()
      .where('id IN (:...ids)', { ids })
      .execute();

    console.log(`   Removed ${nonAdminUsers.length} existing user(s) and their data.\n`);
  } else {
    console.log('   Nothing to remove.\n');
  }

  // ── Step 2: create fresh test users ──────────────────────────────────────────
  console.log('✨  Creating test users...\n');

  let totalUsers = 0;
  let totalRides = 0;

  for (const u of USERS) {
    const email    = `test${u.n}@app.com`;
    const password = await bcrypt.hash(`Test${u.n}`, 12);

    // Build user
    const user = userRepo.create({
      email,
      password,
      firstName:          u.firstName,
      lastName:           u.lastName,
      gender:             u.gender,
      genderPreference:   GenderPreference.ANY,
      userType:           u.userType,
      verificationStatus: VerificationStatus.VERIFIED,
      isEmailVerified:    true,
      isPhoneVerified:    true,
      isActive:           true,
      isSuspended:        false,
      trustScore:         75 + u.n,
      phone:              u.phone,
      verificationSubmittedAt: new Date(),
      // Professional fields
      ...(u.userType === UserType.PROFESSIONAL && {
        jobTitle:     (u as any).jobTitle,
        officeName:   (u as any).officeName,
        companyEmail: email,
        cnicNumber:   (u as any).cnicNumber,
        linkedinUrl:  `https://linkedin.com/in/test${u.n}`,
      }),
      // Student fields
      ...(u.userType === UserType.STUDENT && {
        universityName:    (u as any).universityName,
        degreeDesignation: (u as any).degreeDesignation,
        staffType:         'STUDENT',
        universityEmail:   email,
        cnicNumber:        (u as any).cnicNumber,
        linkedinUrl:       `https://linkedin.com/in/test${u.n}`,
      }),
    });
    await userRepo.save(user);

    // Build vehicle
    const v       = u.vehicle;
    const vehicle = vehicleRepo.create({
      userId:        user.id,
      vehicleType:   VehicleType.CAR,
      make:          v.make,
      model:         v.model,
      year:          v.year,
      color:         v.color,
      licensePlate:  v.plate,
      totalSeats:    v.seats,
      fuelType:      v.fuel,
      engineCC:      v.cc,
      ownerName:     `${u.firstName} ${u.lastName}`,
      chassisNumber: `PKR${u.n.toString().padStart(3, '0')}CHASSIS2024`,
      isActive:      true,
    });
    await vehicleRepo.save(vehicle);

    // Build rides
    const rides = RIDES_PER_USER[u.n] ?? [];
    for (const r of rides) {
      const km = dist(r.origin, r.dest);
      await rideRepo.save(rideRepo.create({
        driverId:              user.id,
        vehicleId:             vehicle.id,
        rideType:              r.rideType,
        status:                RideStatus.ACTIVE,
        originAddress:         r.origin.address,
        originLat:             r.origin.lat,
        originLng:             r.origin.lng,
        destinationAddress:    r.dest.address,
        destinationLat:        r.dest.lat,
        destinationLng:        r.dest.lng,
        departureTime:         daysFromNow(r.daysAhead, r.hour),
        totalSeats:            r.seats,
        availableSeats:        r.seats,
        pricePerSeat:          r.price,
        distanceKm:            km,
        estimatedDurationMins: Math.round(km * 3.5),
        isRecurring:           true,
        notes:                 r.notes,
      } as any));
      totalRides++;
    }

    console.log(
      `  ✅  test${u.n}@app.com  /  Test${u.n}  |  ${u.firstName} ${u.lastName}  |  ${v.make} ${v.model}  |  ${rides.length} rides`,
    );
    totalUsers++;
  }

  await dataSource.destroy();

  console.log('\n─────────────────────────────────────────────────');
  console.log(`  Users created : ${totalUsers}`);
  console.log(`  Rides created : ${totalRides}`);
  console.log('─────────────────────────────────────────────────');
  console.log('\n  Credentials (email / password):');
  for (let i = 1; i <= 5; i++) {
    console.log(`  test${i}@app.com  /  Test${i}`);
  }
  console.log();
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
