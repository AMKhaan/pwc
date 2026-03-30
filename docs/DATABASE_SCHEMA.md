# Database Schema
## RideSync — PostgreSQL

**Version:** 1.0
**Last Updated:** 2026-03-24

---

## Entities Overview

```
users
  └── vehicles (one user → many vehicles)
  └── rides (one user as driver → many rides)
  └── bookings (one user as rider → many bookings)
  └── notifications

rides
  └── bookings (one ride → many bookings)
  └── payments (one ride → one payment per booking)

bookings
  └── payment (one booking → one payment, Discussion Rides only)

university_domains (whitelist)
```

---

## Entity: users

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK, default uuid_generate_v4() | |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Primary login email |
| password | VARCHAR(255) | NULLABLE | Null for pure OAuth users |
| first_name | VARCHAR(100) | NOT NULL | |
| last_name | VARCHAR(100) | NOT NULL | |
| phone | VARCHAR(20) | NULLABLE | |
| avatar_url | TEXT | NULLABLE | Cloudflare R2 URL |
| gender | ENUM('MALE','FEMALE','OTHER') | NULLABLE | |
| gender_preference | ENUM('ANY','SAME_GENDER') | DEFAULT 'ANY' | Ride matching comfort setting |
| user_type | ENUM('PROFESSIONAL','STUDENT') | NOT NULL | |
| verification_status | ENUM('PENDING','VERIFIED','REJECTED') | DEFAULT 'PENDING' | |
| linkedin_id | VARCHAR(255) | NULLABLE, UNIQUE | LinkedIn sub/id |
| linkedin_url | TEXT | NULLABLE | Public profile URL |
| linkedin_data | JSONB | NULLABLE | Raw LinkedIn profile snapshot |
| company_email | VARCHAR(255) | NULLABLE | Verified company email |
| university_email | VARCHAR(255) | NULLABLE | Verified .edu.pk email |
| trust_score | DECIMAL(5,2) | DEFAULT 0 | 0-100, calculated field |
| fcm_token | TEXT | NULLABLE | Firebase push token |
| is_active | BOOLEAN | DEFAULT true | |
| is_email_verified | BOOLEAN | DEFAULT false | |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

---

## Entity: email_verifications

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK → users.id | |
| email | VARCHAR(255) | NOT NULL | The email being verified |
| token | VARCHAR(10) | NOT NULL | 6-digit OTP |
| type | ENUM('PRIMARY','COMPANY','UNIVERSITY') | NOT NULL | |
| expires_at | TIMESTAMP | NOT NULL | OTP valid for 15 mins |
| verified_at | TIMESTAMP | NULLABLE | |
| created_at | TIMESTAMP | DEFAULT NOW() | |

---

## Entity: vehicles

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK → users.id | Owner |
| make | VARCHAR(100) | NOT NULL | e.g. Toyota |
| model | VARCHAR(100) | NOT NULL | e.g. Corolla |
| year | INTEGER | NOT NULL | |
| color | VARCHAR(50) | NOT NULL | |
| license_plate | VARCHAR(20) | NOT NULL | |
| total_seats | INTEGER | NOT NULL | Including driver |
| fuel_type | ENUM('PETROL','DIESEL','CNG','ELECTRIC','HYBRID') | DEFAULT 'PETROL' | |
| avg_fuel_consumption | DECIMAL(5,2) | NOT NULL | KM per liter |
| is_active | BOOLEAN | DEFAULT true | |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

---

## Entity: rides

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| driver_id | UUID | FK → users.id | |
| vehicle_id | UUID | FK → vehicles.id | |
| ride_type | ENUM('OFFICE','UNIVERSITY','DISCUSSION') | NOT NULL | |
| status | ENUM('ACTIVE','IN_PROGRESS','COMPLETED','CANCELLED') | DEFAULT 'ACTIVE' | |
| origin_address | TEXT | NOT NULL | |
| origin_lat | DECIMAL(10,8) | NOT NULL | |
| origin_lng | DECIMAL(11,8) | NOT NULL | |
| destination_address | TEXT | NOT NULL | |
| destination_lat | DECIMAL(10,8) | NOT NULL | |
| destination_lng | DECIMAL(11,8) | NOT NULL | |
| departure_time | TIMESTAMP | NOT NULL | |
| estimated_duration_mins | INTEGER | NULLABLE | From Google Maps |
| distance_km | DECIMAL(8,2) | NULLABLE | From Google Maps |
| total_seats | INTEGER | NOT NULL | Available seats for riders |
| available_seats | INTEGER | NOT NULL | Decrements on booking |
| price_per_seat | DECIMAL(10,2) | NOT NULL | Auto-calculated |
| is_recurring | BOOLEAN | DEFAULT false | |
| recurring_days | TEXT[] | NULLABLE | ['MON','TUE','WED'] |
| notes | TEXT | NULLABLE | |
| discussion_topic | VARCHAR(255) | NULLABLE | Discussion Rides only |
| discussion_fee | DECIMAL(10,2) | NULLABLE | Discussion Rides only |
| host_expertise | VARCHAR(255) | NULLABLE | Discussion Rides only |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

---

## Entity: bookings

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| ride_id | UUID | FK → rides.id | |
| rider_id | UUID | FK → users.id | |
| status | ENUM('PENDING','CONFIRMED','CANCELLED','COMPLETED') | DEFAULT 'PENDING' | |
| seats_booked | INTEGER | DEFAULT 1 | |
| total_amount | DECIMAL(10,2) | NOT NULL | price_per_seat × seats |
| payment_type | ENUM('DIRECT','ESCROW') | NOT NULL | DIRECT for commute, ESCROW for discussion |
| payment_method | ENUM('CASH','JAZZCASH','EASYPAISA') | NULLABLE | |
| confirmed_at | TIMESTAMP | NULLABLE | |
| completed_at | TIMESTAMP | NULLABLE | |
| cancelled_at | TIMESTAMP | NULLABLE | |
| cancellation_reason | TEXT | NULLABLE | |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

---

## Entity: payments

*Only created for Discussion Rides (escrow)*

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| booking_id | UUID | FK → bookings.id, UNIQUE | One payment per booking |
| amount | DECIMAL(10,2) | NOT NULL | Full amount paid by rider |
| platform_fee | DECIMAL(10,2) | NOT NULL | 10-15% commission |
| host_amount | DECIMAL(10,2) | NOT NULL | amount - platform_fee |
| status | ENUM('PENDING','HELD','RELEASED','REFUNDED','FAILED') | DEFAULT 'PENDING' | |
| method | ENUM('JAZZCASH','EASYPAISA') | NOT NULL | |
| transaction_reference | VARCHAR(255) | NULLABLE | Gateway ref |
| gateway_response | JSONB | NULLABLE | Raw gateway response |
| held_at | TIMESTAMP | NULLABLE | |
| released_at | TIMESTAMP | NULLABLE | |
| refunded_at | TIMESTAMP | NULLABLE | |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

---

## Entity: university_domains

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| name | VARCHAR(255) | NOT NULL | e.g. LUMS |
| domain | VARCHAR(255) | UNIQUE, NOT NULL | e.g. lums.edu.pk |
| is_active | BOOLEAN | DEFAULT true | |
| created_at | TIMESTAMP | DEFAULT NOW() | |

**Seed Data:**
| Name | Domain |
|---|---|
| LUMS | lums.edu.pk |
| FAST NUCES | nu.edu.pk |
| UET Lahore | uet.edu.pk |
| COMSATS Lahore | comsats.edu.pk |
| University of Punjab | pu.edu.pk |
| Beaconhouse National | bnu.edu.pk |
| Lahore University | lcwu.edu.pk |

---

## Entity: notifications

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | FK → users.id | |
| title | VARCHAR(255) | NOT NULL | |
| body | TEXT | NOT NULL | |
| type | ENUM('BOOKING','RIDE','PAYMENT','SYSTEM','SOS') | NOT NULL | |
| data | JSONB | NULLABLE | Extra payload |
| is_read | BOOLEAN | DEFAULT false | |
| created_at | TIMESTAMP | DEFAULT NOW() | |

---

## Key Indexes

```sql
-- Ride search (most frequent query)
CREATE INDEX idx_rides_type_status ON rides(ride_type, status);
CREATE INDEX idx_rides_departure ON rides(departure_time);
CREATE INDEX idx_rides_driver ON rides(driver_id);

-- Geo queries (future PostGIS extension)
CREATE INDEX idx_rides_origin ON rides(origin_lat, origin_lng);
CREATE INDEX idx_rides_destination ON rides(destination_lat, destination_lng);

-- Booking lookups
CREATE INDEX idx_bookings_ride ON bookings(ride_id);
CREATE INDEX idx_bookings_rider ON bookings(rider_id);

-- User lookup
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_linkedin ON users(linkedin_id);
