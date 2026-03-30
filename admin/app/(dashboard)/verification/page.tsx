'use client';

import { useEffect, useState, useCallback } from 'react';
import { ShieldCheck, ShieldX, Eye, ChevronLeft, ChevronRight, Link2, Mail, Building2, GraduationCap } from 'lucide-react';
import { api } from '@/lib/api';
import { AdminUser } from '@/lib/types';

const PAGE_SIZE = 15;

interface VerificationItem extends AdminUser {
  pendingType: 'COMPANY' | 'UNIVERSITY' | 'LINKEDIN' | null;
}

export default function VerificationPage() {
  const [items, setItems] = useState<VerificationItem[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [filterType, setFilterType] = useState('');
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [selectedUser, setSelectedUser] = useState<VerificationItem | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/verification-queue', {
        params: { page, limit: PAGE_SIZE, type: filterType || undefined },
      });
      setItems(res.data.data.items);
      setTotal(res.data.data.total);
    } finally {
      setLoading(false);
    }
  }, [page, filterType]);

  useEffect(() => { load(); }, [load]);

  async function handleAction(userId: string, action: 'approve' | 'reject') {
    setActionLoading(`${userId}-${action}`);
    try {
      await api.patch(`/admin/verification/${userId}/${action}`);
      setItems((prev) => prev.filter((i) => i.id !== userId));
      setTotal((t) => t - 1);
      setSelectedUser(null);
    } finally {
      setActionLoading(null);
    }
  }

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const TypeIcon = ({ type }: { type: string }) => {
    if (type === 'COMPANY') return <Building2 size={14} className="text-blue-500" />;
    if (type === 'UNIVERSITY') return <GraduationCap size={14} className="text-purple-500" />;
    return <Link2 size={14} className="text-sky-500" />;
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Verification Queue</h1>
        <p className="text-slate-500 text-sm mt-1">{total} pending verifications</p>
      </div>

      <div className="flex gap-3 mb-6">
        <select
          value={filterType}
          onChange={(e) => { setFilterType(e.target.value); setPage(1); }}
          className="px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
        >
          <option value="">All Types</option>
          <option value="COMPANY">Company Email</option>
          <option value="UNIVERSITY">University Email</option>
          <option value="LINKEDIN">LinkedIn</option>
        </select>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-5 gap-6">
        {/* List */}
        <div className="xl:col-span-3">
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-slate-200 bg-slate-50">
                    <th className="text-left px-4 py-3 font-semibold text-slate-600">User</th>
                    <th className="text-left px-4 py-3 font-semibold text-slate-600">Type</th>
                    <th className="text-left px-4 py-3 font-semibold text-slate-600">Email</th>
                    <th className="text-right px-4 py-3 font-semibold text-slate-600">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {loading ? (
                    <tr>
                      <td colSpan={4} className="text-center py-12">
                        <div className="flex justify-center">
                          <div className="w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
                        </div>
                      </td>
                    </tr>
                  ) : items.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="text-center py-12">
                        <ShieldCheck size={32} className="mx-auto text-green-400 mb-2" />
                        <p className="text-slate-400 text-sm">All caught up! No pending verifications.</p>
                      </td>
                    </tr>
                  ) : (
                    items.map((item) => (
                      <tr
                        key={item.id}
                        onClick={() => setSelectedUser(item)}
                        className={`cursor-pointer transition-colors ${
                          selectedUser?.id === item.id ? 'bg-blue-50' : 'hover:bg-slate-50'
                        }`}
                      >
                        <td className="px-4 py-3">
                          <p className="font-medium text-slate-900">{item.firstName} {item.lastName}</p>
                          <p className="text-xs text-slate-400">{item.email}</p>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-1.5">
                            {item.pendingType && <TypeIcon type={item.pendingType} />}
                            <span className="text-xs text-slate-600 capitalize">
                              {item.pendingType?.toLowerCase() ?? '—'}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-500 max-w-[140px] truncate">
                          {item.pendingType === 'COMPANY'
                            ? item.companyEmail
                            : item.pendingType === 'UNIVERSITY'
                            ? item.universityEmail
                            : 'LinkedIn OAuth'}
                        </td>
                        <td className="px-4 py-3 text-right">
                          <button className="p-1.5 hover:bg-slate-100 rounded-lg text-slate-400 hover:text-slate-600">
                            <Eye size={15} />
                          </button>
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
                  <span className="px-2 py-1 text-sm text-slate-700">{page}/{totalPages}</span>
                  <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
                    className="p-1.5 rounded-lg hover:bg-slate-100 disabled:opacity-40 text-slate-600">
                    <ChevronRight size={16} />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Detail panel */}
        <div className="xl:col-span-2">
          <div className="bg-white rounded-xl border border-slate-200 p-6 sticky top-8">
            {!selectedUser ? (
              <div className="text-center py-8">
                <Eye size={28} className="mx-auto text-slate-300 mb-2" />
                <p className="text-sm text-slate-400">Select a user to review</p>
              </div>
            ) : (
              <div>
                <div className="flex items-center gap-3 mb-5">
                  <div className="w-10 h-10 rounded-full bg-blue-100 text-blue-700 font-bold text-sm flex items-center justify-center">
                    {selectedUser.firstName[0]}{selectedUser.lastName[0]}
                  </div>
                  <div>
                    <p className="font-semibold text-slate-900">{selectedUser.firstName} {selectedUser.lastName}</p>
                    <p className="text-xs text-slate-400">{selectedUser.email}</p>
                  </div>
                </div>

                <div className="space-y-3 mb-6">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">User Type</span>
                    <span className="font-medium text-slate-700">{selectedUser.userType}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Current Status</span>
                    <span className="font-medium text-slate-700">{selectedUser.verificationStatus}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Trust Score</span>
                    <span className="font-medium text-slate-700">{selectedUser.trustScore}/100</span>
                  </div>
                  {selectedUser.pendingType !== 'LINKEDIN' && (
                    <div className="border-t border-slate-100 pt-3">
                      <p className="text-xs text-slate-400 mb-1">
                        {selectedUser.pendingType === 'COMPANY' ? 'Company Email' : 'University Email'}
                      </p>
                      <div className="flex items-center gap-2 p-2 bg-slate-50 rounded-lg">
                        <Mail size={14} className="text-slate-400" />
                        <span className="text-sm text-slate-700">
                          {selectedUser.pendingType === 'COMPANY'
                            ? selectedUser.companyEmail
                            : selectedUser.universityEmail}
                        </span>
                      </div>
                    </div>
                  )}
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={() => handleAction(selectedUser.id, 'approve')}
                    disabled={!!actionLoading}
                    className="flex-1 flex items-center justify-center gap-1.5 py-2.5 bg-green-600 hover:bg-green-700 disabled:opacity-60 text-white font-medium rounded-lg text-sm transition-colors"
                  >
                    <ShieldCheck size={15} />
                    Approve
                  </button>
                  <button
                    onClick={() => handleAction(selectedUser.id, 'reject')}
                    disabled={!!actionLoading}
                    className="flex-1 flex items-center justify-center gap-1.5 py-2.5 bg-red-50 hover:bg-red-100 disabled:opacity-60 text-red-600 font-medium rounded-lg text-sm transition-colors"
                  >
                    <ShieldX size={15} />
                    Reject
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
