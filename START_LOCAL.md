# Running RideSync Locally

## Step 1 — Start Docker Desktop
Open Docker Desktop from the Start menu. Wait until the whale icon in the taskbar is solid (not animated).

---

## Step 2 — Start PostgreSQL + Redis
Open a terminal in `C:/Users/ahmad/Desktop/PwC/` and run:

```bash
docker compose -f docker-compose.dev.yml up -d
```

Verify they're running:
```bash
docker ps
```
You should see `ridesync_postgres` and `ridesync_redis`.

---

## Step 3 — Start the Backend API
Open a new terminal in `C:/Users/ahmad/Desktop/PwC/backend/`:

```bash
npm run start:dev
```

First run will auto-create all database tables (TypeORM synchronize=true in dev).

Once you see `RideSync API running on port 3000`, open in browser:
- **Swagger API Docs**: http://localhost:3000/api/docs

---

## Step 4 — Seed the Database (first time only)
In a new terminal inside `backend/`:

```bash
npm run seed:universities
npm run seed:admin
```

Admin credentials:
- **Email**: admin@ridesync.pk
- **Password**: Admin@12345

---

## Step 5 — Start the Admin Dashboard
Open a new terminal in `C:/Users/ahmad/Desktop/PwC/admin/`:

```bash
npm run dev
```

Open: http://localhost:3001
Login with the admin credentials above.

---

## Quick Test Flow (via Swagger at http://localhost:3000/api/docs)

1. `POST /api/v1/auth/register` — create a test user
2. Check terminal for the OTP (printed to console, Resend not configured yet)
3. `POST /api/v1/auth/verify-email` — verify with the OTP
4. `POST /api/v1/auth/login` — get JWT token
5. Click **Authorize** in Swagger, paste the token
6. `GET /api/v1/users/me` — check profile
7. `POST /api/v1/users/me/vehicles` — add a vehicle
8. `POST /api/v1/rides` — create a ride
9. `GET /api/v1/rides/search` — search rides

---

## Stopping Everything
```bash
docker compose -f docker-compose.dev.yml down
```

To also delete all data:
```bash
docker compose -f docker-compose.dev.yml down -v
```
