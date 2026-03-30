'use client';

import { useEffect, useState } from 'react';
import {
  Users,
  Car,
  BookOpen,
  DollarSign,
  ShieldCheck,
  TrendingUp,
  AlertCircle,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';
import StatsCard from '@/components/stats-card';
import { api } from '@/lib/api';
import { DashboardStats, PlatformEarnings } from '@/lib/types';

const RIDE_COLORS = ['#6366F1', '#16A34A', '#9333EA'];

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [earnings, setEarnings] = useState<PlatformEarnings | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [statsRes, earningsRes] = await Promise.all([
          api.get('/admin/stats'),
          api.get('/payments/platform-earnings'),
        ]);
        setStats(statsRes.data.data);
        setEarnings(earningsRes.data.data);
      } catch {
        // stats will remain null, handled in UI
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const rideTypeData = [
    { name: 'Office', value: 45 },
    { name: 'University', value: 35 },
    { name: 'Discussion', value: 20 },
  ];

  const weeklyData = [
    { day: 'Mon', rides: 12, bookings: 28 },
    { day: 'Tue', rides: 18, bookings: 42 },
    { day: 'Wed', rides: 15, bookings: 35 },
    { day: 'Thu', rides: 22, bookings: 55 },
    { day: 'Fri', rides: 28, bookings: 68 },
    { day: 'Sat', rides: 35, bookings: 82 },
    { day: 'Sun', rides: 20, bookings: 48 },
  ];

  const formatPKR = (n: number) =>
    `PKR ${n.toLocaleString('en-PK')}`;

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
        <p className="text-slate-500 text-sm mt-1">Platform overview and key metrics</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
        <StatsCard
          title="Total Users"
          value={stats?.totalUsers ?? '—'}
          subtitle={`${stats?.verifiedUsers ?? 0} verified`}
          icon={Users}
          color="blue"
        />
        <StatsCard
          title="Active Rides"
          value={stats?.activeRides ?? '—'}
          subtitle={`${stats?.totalRides ?? 0} total`}
          icon={Car}
          color="green"
        />
        <StatsCard
          title="Total Bookings"
          value={stats?.totalBookings ?? '—'}
          subtitle={`${stats?.completedBookings ?? 0} completed`}
          icon={BookOpen}
          color="purple"
        />
        <StatsCard
          title="Platform Earnings"
          value={earnings ? formatPKR(earnings.totalEarnings) : '—'}
          subtitle={`${earnings ? formatPKR(earnings.heldEarnings) : '—'} held`}
          icon={DollarSign}
          color="orange"
        />
      </div>

      {/* Secondary Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        <StatsCard
          title="Verification Queue"
          value={stats?.pendingVerifications ?? '—'}
          subtitle="Awaiting review"
          icon={ShieldCheck}
          color="orange"
        />
        <StatsCard
          title="Verification Rate"
          value={
            stats
              ? `${Math.round((stats.verifiedUsers / Math.max(stats.totalUsers, 1)) * 100)}%`
              : '—'
          }
          subtitle="Users fully verified"
          icon={TrendingUp}
          color="green"
        />
        <StatsCard
          title="Booking Rate"
          value={
            stats
              ? `${Math.round((stats.completedBookings / Math.max(stats.totalBookings, 1)) * 100)}%`
              : '—'
          }
          subtitle="Bookings completed"
          icon={AlertCircle}
          color="blue"
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Weekly Activity */}
        <div className="xl:col-span-2 bg-white rounded-xl border border-slate-200 p-6">
          <h2 className="text-base font-semibold text-slate-900 mb-4">Weekly Activity</h2>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={weeklyData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="rides" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#6366F1" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#6366F1" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="bookings" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#16A34A" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#16A34A" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="day" tick={{ fontSize: 12, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 12, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0', fontSize: 13 }}
              />
              <Area type="monotone" dataKey="rides" name="Rides" stroke="#6366F1" fill="url(#rides)" strokeWidth={2} />
              <Area type="monotone" dataKey="bookings" name="Bookings" stroke="#16A34A" fill="url(#bookings)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Ride Type Distribution */}
        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h2 className="text-base font-semibold text-slate-900 mb-4">Ride Types</h2>
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie
                data={rideTypeData}
                cx="50%"
                cy="45%"
                innerRadius={55}
                outerRadius={80}
                paddingAngle={3}
                dataKey="value"
              >
                {rideTypeData.map((_, i) => (
                  <Cell key={i} fill={RIDE_COLORS[i]} />
                ))}
              </Pie>
              <Legend
                iconType="circle"
                iconSize={8}
                formatter={(value) => <span style={{ fontSize: 12, color: '#64748b' }}>{value}</span>}
              />
              <Tooltip formatter={(v) => `${v}%`} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
