'use client';

import { useEffect, useState, useCallback } from 'react';
import { Search, MapPin, Calendar, ChevronLeft, ChevronRight, XCircle } from 'lucide-react';
import { api } from '@/lib/api';
import { AdminRide } from '@/lib/types';

const TYPE_STYLES: Record<string, string> = {
  OFFICE: 'bg-blue-50 text-blue-700',
  UNIVERSITY: 'bg-purple-50 text-purple-700',
  DISCUSSION: 'bg-orange-50 text-orange-700',
};

const STATUS_STYLES: Record<string, string> = {
  ACTIVE: 'bg-slate-100 text-slate-600',
  IN_PROGRESS: 'bg-green-100 text-green-700',
  COMPLETED: 'bg-blue-100 text-blue-700',
  CANCELLED: 'bg-red-100 text-red-600',
};

const PAGE_SIZE = 15;

export default function RidesPage() {
  const [rides, setRides] = useState<AdminRide[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/rides', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: search || undefined,
          type: filterType || undefined,
          status: filterStatus || undefined,
        },
      });
      setRides(res.data.data.rides);
      setTotal(res.data.data.total);
    } finally {
      setLoading(false);
    }
  }, [page, search, filterType, filterStatus]);

  useEffect(() => { load(); }, [load]);

  async function cancelRide(id: string) {
    if (!confirm('Cancel this ride? All bookings will be notified.')) return;
    setCancelling(id);
    try {
      await api.patch(`/rides/${id}/cancel`);
      setRides((prev) =>
        prev.map((r) => (r.id === id ? { ...r, status: 'CANCELLED' } : r))
      );
    } finally {
      setCancelling(null);
    }
  }

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Rides</h1>
        <p className="text-slate-500 text-sm mt-1">{total} total rides</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by driver or location..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="w-full pl-9 pr-4 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div className="flex gap-2">
          <select
            value={filterType}
            onChange={(e) => { setFilterType(e.target.value); setPage(1); }}
            className="px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
          >
            <option value="">All Types</option>
            <option value="OFFICE">Office</option>
            <option value="UNIVERSITY">University</option>
            <option value="DISCUSSION">Discussion</option>
          </select>
          <select
            value={filterStatus}
            onChange={(e) => { setFilterStatus(e.target.value); setPage(1); }}
            className="px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
          >
            <option value="">All Status</option>
            <option value="ACTIVE">Scheduled</option>
            <option value="IN_PROGRESS">In Progress</option>
            <option value="COMPLETED">Completed</option>
            <option value="CANCELLED">Cancelled</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Type</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Route</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Driver</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Departure</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Seats</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Price</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Status</th>
                <th className="text-right px-4 py-3 font-semibold text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={8} className="text-center py-12">
                    <div className="flex justify-center">
                      <div className="w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
                    </div>
                  </td>
                </tr>
              ) : rides.length === 0 ? (
                <tr>
                  <td colSpan={8} className="text-center py-12 text-slate-400 text-sm">
                    No rides found
                  </td>
                </tr>
              ) : (
                rides.map((ride) => (
                  <tr key={ride.id} className="hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${TYPE_STYLES[ride.type]}`}>
                        {ride.type === 'OFFICE' ? 'Office' : ride.type === 'UNIVERSITY' ? 'University' : 'Discussion'}
                      </span>
                    </td>
                    <td className="px-4 py-3 max-w-[200px]">
                      <div className="flex items-start gap-1.5">
                        <MapPin size={13} className="text-slate-400 mt-0.5 shrink-0" />
                        <div>
                          <p className="text-slate-700 truncate">{ride.originAddress}</p>
                          <p className="text-slate-400 text-xs truncate">→ {ride.destinationAddress}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <p className="text-slate-700">{ride.driver.firstName} {ride.driver.lastName}</p>
                      <p className="text-xs text-slate-400">{ride.driver.email}</p>
                    </td>
                    <td className="px-4 py-3 text-slate-600 text-xs whitespace-nowrap">
                      <div className="flex items-center gap-1">
                        <Calendar size={12} className="text-slate-400" />
                        {new Date(ride.departureTime).toLocaleString('en-PK', {
                          day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                        })}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-700 text-center">{ride.availableSeats}</td>
                    <td className="px-4 py-3 text-slate-700 font-medium whitespace-nowrap">
                      PKR {ride.pricePerSeat.toLocaleString()}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${STATUS_STYLES[ride.status]}`}>
                        {ride.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      {(ride.status === 'ACTIVE' || ride.status === 'IN_PROGRESS') && (
                        <button
                          onClick={() => cancelRide(ride.id)}
                          disabled={cancelling === ride.id}
                          className="inline-flex items-center gap-1 px-3 py-1.5 bg-red-50 hover:bg-red-100 text-red-600 rounded-lg text-xs font-medium transition-colors disabled:opacity-50"
                        >
                          <XCircle size={13} />
                          Cancel
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-200">
            <p className="text-sm text-slate-500">
              {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, total)} of {total}
            </p>
            <div className="flex gap-1 items-center">
              <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1}
                className="p-1.5 rounded-lg hover:bg-slate-100 disabled:opacity-40 text-slate-600">
                <ChevronLeft size={16} />
              </button>
              <span className="px-3 py-1.5 text-sm text-slate-700">{page} / {totalPages}</span>
              <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
                className="p-1.5 rounded-lg hover:bg-slate-100 disabled:opacity-40 text-slate-600">
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
