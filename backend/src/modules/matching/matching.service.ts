import { Injectable } from '@nestjs/common';

const FUEL_PRICE_PKR = 265;

export interface RoutePoint {
  lat: number;
  lng: number;
}

@Injectable()
export class MatchingService {

  // ─── Avg fuel consumption by vehicle type + engine CC ────────────────────────
  getAvgConsumption(vehicleType: string, engineCC: number): number {
    if (vehicleType === 'BIKE') return 40;
    if (!engineCC) return 12;
    if (engineCC < 800) return 15;
    if (engineCC < 1000) return 13;
    if (engineCC < 1300) return 12;
    return 10;
  }

  // ─── Price per seat ───────────────────────────────────────────────────────────
  calculatePricePerSeat(
    distanceKm: number,
    vehicleType: string,
    engineCC: number,
    passengerSeats: number,
  ): number {
    const avgKmPerLiter = this.getAvgConsumption(vehicleType, engineCC);
    const liters = distanceKm / avgKmPerLiter;
    const totalFuelCost = liters * FUEL_PRICE_PKR;
    const pricePerSeat = totalFuelCost / (passengerSeats + 1);
    return Math.ceil(pricePerSeat / 10) * 10;
  }

  // ─── Road distance via OSRM (falls back to Haversine on error) ───────────────
  async getRoadDistanceKm(
    originLat: number, originLng: number,
    destLat: number, destLng: number,
  ): Promise<number> {
    try {
      const url = `http://router.project-osrm.org/route/v1/driving/${originLng},${originLat};${destLng},${destLat}?overview=false`;
      const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
      const data = await res.json() as any;
      if (data.code === 'Ok' && data.routes?.length) {
        return parseFloat((data.routes[0].distance / 1000).toFixed(2));
      }
    } catch (_) {}
    return this.calculateDistance(originLat, originLng, destLat, destLng);
  }

  // ─── Fetch full route polyline from OSRM ──────────────────────────────────────
  // Returns array of {lat, lng} points sampled every ~400m along the route
  async getRoutePolyline(
    originLat: number, originLng: number,
    destLat: number, destLng: number,
  ): Promise<RoutePoint[]> {
    try {
      const url = `http://router.project-osrm.org/route/v1/driving/${originLng},${originLat};${destLng},${destLat}?overview=full&geometries=geojson`;
      const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
      const data = await res.json() as any;

      if (data.code !== 'Ok' || !data.routes?.length) {
        return this.fallbackPolyline(originLat, originLng, destLat, destLng);
      }

      const coords: [number, number][] = data.routes[0].geometry.coordinates; // [lng, lat]
      // Sample: keep every point but limit to ~100 points max
      const step = Math.max(1, Math.floor(coords.length / 100));
      const sampled: RoutePoint[] = [];
      for (let i = 0; i < coords.length; i += step) {
        sampled.push({ lat: coords[i][1], lng: coords[i][0] });
      }
      // Always include last point
      const last = coords[coords.length - 1];
      sampled.push({ lat: last[1], lng: last[0] });

      return sampled;
    } catch (_) {
      return this.fallbackPolyline(originLat, originLng, destLat, destLng);
    }
  }

  // Fallback: straight line between origin and dest with intermediate points
  private fallbackPolyline(
    originLat: number, originLng: number,
    destLat: number, destLng: number,
  ): RoutePoint[] {
    const points: RoutePoint[] = [];
    const steps = 10;
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      points.push({
        lat: originLat + (destLat - originLat) * t,
        lng: originLng + (destLng - originLng) * t,
      });
    }
    return points;
  }

  // ─── Route corridor matching ──────────────────────────────────────────────────
  // Returns true if rider's pickup AND dropoff fall on the driver's route
  // pickup must come before dropoff in the route order
  isRiderOnRoute(
    polyline: RoutePoint[],
    riderPickupLat: number, riderPickupLng: number,
    riderDropoffLat: number, riderDropoffLng: number,
    thresholdKm = 1.5,
  ): boolean {
    if (!polyline || polyline.length < 2) return false;

    // Find index of closest polyline point to rider's pickup
    let pickupIndex = -1;
    let pickupMinDist = Infinity;
    for (let i = 0; i < polyline.length; i++) {
      const d = this.calculateDistance(
        polyline[i].lat, polyline[i].lng,
        riderPickupLat, riderPickupLng,
      );
      if (d < pickupMinDist) {
        pickupMinDist = d;
        pickupIndex = i;
      }
    }

    if (pickupMinDist > thresholdKm) return false; // pickup too far from route

    // Find closest point to rider's dropoff — must be AFTER pickupIndex
    let dropoffMinDist = Infinity;
    for (let i = pickupIndex; i < polyline.length; i++) {
      const d = this.calculateDistance(
        polyline[i].lat, polyline[i].lng,
        riderDropoffLat, riderDropoffLng,
      );
      if (d < dropoffMinDist) dropoffMinDist = d;
    }

    return dropoffMinDist <= thresholdKm;
  }

  // ─── Legacy: simple endpoint proximity check (kept for fallback) ──────────────
  isRouteMatch(
    driverOriginLat: number, driverOriginLng: number,
    driverDestLat: number, driverDestLng: number,
    riderOriginLat: number, riderOriginLng: number,
    riderDestLat: number, riderDestLng: number,
    thresholdKm = 3,
  ): boolean {
    const pickupDistance = this.calculateDistance(
      driverOriginLat, driverOriginLng,
      riderOriginLat, riderOriginLng,
    );
    const dropoffDistance = this.calculateDistance(
      driverDestLat, driverDestLng,
      riderDestLat, riderDestLng,
    );
    return pickupDistance <= thresholdKm && dropoffDistance <= thresholdKm;
  }

  // ─── Haversine distance (km) ──────────────────────────────────────────────────
  calculateDistance(
    lat1: number, lng1: number,
    lat2: number, lng2: number,
  ): number {
    const R = 6371;
    const dLat = this.toRad(lat2 - lat1);
    const dLng = this.toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return parseFloat((R * c).toFixed(2));
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
