# Technical Architecture
## RideSync

**Version:** 1.0
**Last Updated:** 2026-03-24

---

## 1. Architecture Pattern

**Modular Monolith** → designed to split into microservices at scale

Single deployable backend with clean module separation. Each module owns its routes, services, and DB interactions.

---

## 2. Tech Stack

### Backend
| Layer | Technology | Reason |
|---|---|---|
| Runtime | Node.js | Fast, async, large ecosystem |
| Framework | NestJS (TypeScript) | Structured, scalable, enterprise-grade |
| Primary DB | PostgreSQL | Relational data, ACID compliance |
| Cache / Queue | Redis | Sessions, real-time, background jobs |
| Real-time | Socket.io | Live location, ride status updates |
| Auth | JWT + LinkedIn OAuth | Stateless, secure |

### Mobile
| Layer | Technology | Reason |
|---|---|---|
| Framework | Flutter (Dart) | Single codebase, Android + iOS, near-native |
| State Management | Riverpod | Scalable, testable |
| Maps | Google Maps Flutter Plugin | Best Pakistan coverage |
| HTTP | Dio | Interceptors, error handling |
| Local Storage | Flutter Secure Storage | Tokens, sensitive data |

### Admin Dashboard
| Layer | Technology |
|---|---|
| Framework | Next.js (TypeScript) |
| UI | shadcn/ui + Tailwind CSS |
| Charts | Recharts |

### Infrastructure
| Purpose | Service |
|---|---|
| Hosting | DigitalOcean App Platform |
| Database | DigitalOcean Managed PostgreSQL |
| Cache | DigitalOcean Managed Redis |
| File Storage | Cloudflare R2 |
| Email | Resend |
| Push Notifications | Firebase Cloud Messaging |
| Maps | Google Maps API |
| Error Tracking | Sentry |
| CI/CD | GitHub Actions |

### External APIs
| Purpose | Service |
|---|---|
| Professional Verification | LinkedIn OAuth 2.0 |
| Payment (PKR) | JazzCash API + EasyPaisa API |
| Cost Calculation | Google Distance Matrix API |

---

## 3. System Diagram

```
┌─────────────────────────────────────────┐
│           Flutter Mobile App             │
│         (Android primary / iOS)          │
└──────────────────┬──────────────────────┘
                   │ HTTPS + WSS
┌──────────────────▼──────────────────────┐
│          NestJS Backend API              │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │  Auth   │ │  Ride   │ │ Booking  │  │
│  │ Module  │ │ Module  │ │  Module  │  │
│  └─────────┘ └─────────┘ └──────────┘  │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │  User   │ │Payment  │ │  Match   │  │
│  │ Module  │ │ Module  │ │  Module  │  │
│  └─────────┘ └─────────┘ └──────────┘  │
│  ┌─────────┐ ┌─────────┐               │
│  │Notif.   │ │Real-time│               │
│  │ Module  │ │ Module  │               │
│  └─────────┘ └─────────┘               │
└──────┬───────────────┬─────────────────┘
       │               │
┌──────▼──────┐  ┌─────▼──────┐
│ PostgreSQL  │  │   Redis    │
│  (Primary)  │  │  (Cache)   │
└─────────────┘  └────────────┘
       │
┌──────▼──────────────────────────────────┐
│           External Services              │
│  LinkedIn OAuth | Google Maps           │
│  JazzCash | EasyPaisa | FCM             │
│  Resend | Cloudflare R2 | Sentry        │
└─────────────────────────────────────────┘
```

---

## 4. Backend Module Structure

```
backend/
├── src/
│   ├── modules/
│   │   ├── auth/          # Login, OAuth, JWT, email verification
│   │   ├── users/         # Profile, verification status, preferences
│   │   ├── rides/         # Create, search, manage rides
│   │   ├── bookings/      # Book, cancel, confirm rides
│   │   ├── payments/      # Escrow, JazzCash, EasyPaisa
│   │   ├── matching/      # Route matching algorithm
│   │   ├── notifications/ # FCM push, email notifications
│   │   └── realtime/      # Socket.io live location
│   ├── common/
│   │   ├── guards/        # Auth guards, role guards
│   │   ├── decorators/    # Custom decorators
│   │   ├── filters/       # Exception filters
│   │   ├── interceptors/  # Logging, transform
│   │   └── pipes/         # Validation pipes
│   ├── config/            # Environment config
│   └── database/          # Migrations, seeds
```

---

## 5. Security Standards

- All endpoints protected by JWT guard (except auth routes)
- Rate limiting on all public endpoints
- Input validation via class-validator on all DTOs
- Passwords hashed with bcrypt (salt rounds: 12)
- LinkedIn OAuth tokens never stored — only profile data
- Environment variables via .env (never committed to git)
- HTTPS enforced on all endpoints
- SQL injection prevention via TypeORM parameterized queries
- XSS prevention via input sanitization
- CORS configured for known origins only
- Helmet.js for HTTP security headers

---

## 6. Build Order (Development Phases)

| Phase | What We Build |
|---|---|
| Phase 1 | Backend foundation — NestJS setup, DB schema, Auth module |
| Phase 2 | Core ride modules — Rides, Bookings, Matching |
| Phase 3 | Payment module — Escrow logic, JazzCash/EasyPaisa |
| Phase 4 | Real-time — Socket.io live location |
| Phase 5 | Flutter mobile app |
| Phase 6 | Admin dashboard (Next.js) |
| Phase 7 | Integrations — LinkedIn OAuth, FCM, Google Maps |
| Phase 8 | Testing, security audit, deployment |

---
