export interface AdminUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  userType: 'PROFESSIONAL' | 'STUDENT';
  verificationStatus: 'PENDING' | 'VERIFIED' | 'REJECTED';
  gender: 'MALE' | 'FEMALE' | 'OTHER' | null;
  trustScore: number;
  isActive: boolean;
  isSuspended: boolean;
  companyEmail: string | null;
  universityEmail: string | null;
  linkedinUrl: string | null;
  createdAt: string;
}

export interface AdminRide {
  id: string;
  type: 'OFFICE' | 'UNIVERSITY' | 'DISCUSSION';
  status: 'ACTIVE' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
  originAddress: string;
  destinationAddress: string;
  departureTime: string;
  availableSeats: number;
  pricePerSeat: number;
  topic: string | null;
  driver: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
  createdAt: string;
}

export interface AdminBooking {
  id: string;
  status: 'PENDING' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED';
  paymentType: 'DIRECT' | 'ESCROW';
  paymentMethod: 'CASH' | 'JAZZCASH' | 'EASYPAISA' | null;
  totalAmount: number;
  createdAt: string;
  rider: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
  ride: {
    id: string;
    type: string;
    originAddress: string;
    destinationAddress: string;
    departureTime: string;
  };
}

export interface AdminPayment {
  id: string;
  status: 'PENDING' | 'HELD' | 'RELEASED' | 'REFUNDED' | 'FAILED';
  amount: number;
  platformFee: number;
  hostAmount: number;
  method: 'JAZZCASH' | 'EASYPAISA';
  transactionReference: string | null;
  createdAt: string;
  releasedAt: string | null;
  booking: {
    id: string;
    rider: { firstName: string; lastName: string };
    ride: { type: string; originAddress: string; destinationAddress: string };
  };
}

export interface DashboardStats {
  totalUsers: number;
  verifiedUsers: number;
  activeRides: number;
  totalRides: number;
  totalBookings: number;
  completedBookings: number;
  platformEarnings: number;
  pendingVerifications: number;
}

export interface PlatformEarnings {
  totalEarnings: number;
  releasedEarnings: number;
  heldEarnings: number;
  totalTransactions: number;
}
