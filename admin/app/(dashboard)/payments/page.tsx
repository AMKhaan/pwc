'use client';

import { useEffect, useState, useCallback } from 'react';
import { DollarSign, TrendingUp, Clock, RefreshCw, ChevronLeft, ChevronRight } from 'lucide-react';
import { api } from '@/lib/api';
import { AdminPayment, PlatformEarnings } from '@/lib/types';
import StatsCard from '@/components/stats-card';

const STATUS_STYLES: Record<string, string> = {
  PENDING: 'bg-slate-100 text-slate-600',
  HELD: 'bg-yellow-100 text-yellow-700',
  RELEASED: 'bg-green-100 text-green-700',
  REFUNDED: 'bg-blue-100 text-blue-700',
  FAILED: 'bg-red-100 text-red-600',
};

const PAGE_SIZE = 15;

export default function PaymentsPage() {
  const [payments, setPayments] = useState<AdminPayment[]>([]);
  const [earnings, setEarnings] = useState<PlatformEarnings | null>(null);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [filterStatus, setFilterStatus] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [paymentsRes, earningsRes] = await Promise.all([
        api.get('/admin/payments', {
          params: { page, limit: PAGE_SIZE, status: filterStatus || undefined },
        }),
        api.get('/payments/platform-earnings'),
      ]);
      setPayments(paymentsRes.data.data.payments);
      setTotal(paymentsRes.data.data.total);
      setEarnings(earningsRes.data.data);
    } finally {
      setLoading(false);
    }
  }, [page, filterStatus]);

  useEffect(() => { load(); }, [load]);

  const totalPages = Math.ceil(total / PAGE_SIZE);
  const fmt = (n: number) => `PKR ${n.toLocaleString('en-PK')}`;

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Payments</h1>
        <p className="text-slate-500 text-sm mt-1">Escrow transactions and platform earnings</p>
      </div>

      {/* Earnings Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
        <StatsCard
          title="Total Earnings"
          value={earnings ? fmt(earnings.totalEarnings) : '—'}
          subtitle="All time commission"
          icon={DollarSign}
          color="green"
        />
        <StatsCard
          title="Released"
          value={earnings ? fmt(earnings.releasedEarnings) : '—'}
          subtitle="Paid out to drivers"
          icon={TrendingUp}
          color="blue"
        />
        <StatsCard
          title="Held in Escrow"
          value={earnings ? fmt(earnings.heldEarnings) : '—'}
          subtitle="Pending release"
          icon={Clock}
          color="orange"
        />
        <StatsCard
          title="Transactions"
          value={earnings?.totalTransactions ?? '—'}
          subtitle="Total payment records"
          icon={RefreshCw}
          color="purple"
        />
      </div>

      {/* Filter */}
      <div className="flex gap-3 mb-6">
        <select
          value={filterStatus}
          onChange={(e) => { setFilterStatus(e.target.value); setPage(1); }}
          className="px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
        >
          <option value="">All Status</option>
          <option value="PENDING">Pending</option>
          <option value="HELD">Held</option>
          <option value="RELEASED">Released</option>
          <option value="REFUNDED">Refunded</option>
          <option value="FAILED">Failed</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Rider</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Ride</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Amount</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Platform Fee</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Gateway</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Status</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="text-center py-12">
                    <div className="flex justify-center">
                      <div className="w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
                    </div>
                  </td>
                </tr>
              ) : payments.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-slate-400 text-sm">
                    No payments found
                  </td>
                </tr>
              ) : (
                payments.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3 font-medium text-slate-800">
                      {p.booking.rider.firstName} {p.booking.rider.lastName}
                    </td>
                    <td className="px-4 py-3 max-w-[180px]">
                      <p className="text-slate-600 text-xs truncate">{p.booking.ride.originAddress}</p>
                      <p className="text-slate-400 text-xs truncate">→ {p.booking.ride.destinationAddress}</p>
                    </td>
                    <td className="px-4 py-3 font-semibold text-slate-900 whitespace-nowrap">
                      {fmt(p.amount)}
                    </td>
                    <td className="px-4 py-3 text-green-700 font-medium whitespace-nowrap">
                      {fmt(p.platformFee)}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${
                        p.method === 'JAZZCASH'
                          ? 'bg-red-50 text-red-700'
                          : 'bg-green-50 text-green-700'
                      }`}>
                        {p.method === 'JAZZCASH' ? 'JazzCash' : 'EasyPaisa'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${STATUS_STYLES[p.status]}`}>
                        {p.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-500 text-xs whitespace-nowrap">
                      {new Date(p.createdAt).toLocaleDateString('en-PK', {
                        day: 'numeric', month: 'short', year: 'numeric',
                      })}
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
