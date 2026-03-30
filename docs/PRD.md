# Product Requirements Document (PRD)
## RideSync — Professional Ride Sharing Platform

**Version:** 1.0
**Status:** In Progress
**Last Updated:** 2026-03-24

---

## 1. Product Overview

RideSync is a verified professional ride-sharing platform. Unlike Careem or Uber (hire-a-driver), RideSync connects people who are already making a trip with others going the same way — reducing cost per head while maintaining trust through professional identity verification.

**Launch Market:** Lahore, Pakistan
**Target Launch:** V1 MVP

---

## 2. The Problem

- Fuel prices in Pakistan are at record highs (PKR 250-280/liter)
- Daily commuters drive alone spending full fuel cost
- Existing ride-hire apps (Careem, Bykea) are expensive and have stranger-safety concerns
- No verified professional carpooling platform exists in Pakistan

---

## 3. Core Value Proposition

1. **Cost Reduction** — Split fuel cost equally among riders
2. **Verified Identity** — LinkedIn + company/university email = only real professionals
3. **Drive Talks** — Monetize commute time for professional discussions

---

## 4. User Types

| Type | Verification Method | Ride Access |
|---|---|---|
| Corporate Professional | Company email + LinkedIn | Office Rides + Discussion Rides |
| Student | University email (.edu.pk) | University Rides |
| Discussion Host | LinkedIn (min. 3 years experience) | Discussion Rides (host only) |

---

## 5. Ride Types (V1 Scope)

### 5.1 Office Ride (CommuteShare)
- Driver posts recurring route (Home → Office)
- Sets days, time, available seats
- Riders browse and book
- Cost auto-calculated: (distance × avg fuel consumption) ÷ seats
- Payment: direct between users (cash / JazzCash / EasyPaisa)
- Platform cut: PKR 0

### 5.2 University Ride (CampusRide)
- Same as Office Ride
- Restricted to verified university email users
- University email domains whitelisted (LUMS, FAST, UET, COMSATS, Punjab Uni, etc.)
- Platform cut: PKR 0

### 5.3 Discussion Ride (DriveDesk)
- Host (driver) creates ride with: topic, expertise area, duration, fee
- Guests browse by topic/expertise and book
- Platform holds payment (escrow)
- Payment released to host after ride completion confirmed
- Platform cut: 10-15%

---

## 6. Safety Model

Trust is built through layers, not restrictions:

1. **Verified identity** (LinkedIn + email)
2. **LinkedIn mutual connections** displayed on profile
3. **Ride history score**
4. **Profile completeness score**
5. **Live trip sharing** — rider shares live location with any contact
6. **SOS button** — visible during active ride
7. **Gender comfort preference** — rider can set same-gender preference (algorithm respects silently)

---

## 7. Payment Flow

### Commute Rides (Office + University)
- Platform calculates exact cost per seat
- Displays to both driver and rider
- Payment handled directly between users
- Platform does NOT process money

### Discussion Rides
- Rider pays through platform at booking
- Platform holds in escrow
- Ride completed → host confirms → platform releases payment in 24hrs
- Platform deducts 10-15% commission

---

## 8. What's NOT in V1

- Intercity rides
- International / flight sharing
- Road trips / vacations
- In-app chat (use WhatsApp share link)
- Rating system (Phase 2)
- Corporate plans (Phase 2)
- In-app wallet (Phase 2)

---

## 9. Success Metrics (V1)

- 500 registered verified users in Lahore
- 100 active weekly rides posted
- 20 Discussion Rides booked per week
- Zero safety incidents

---
