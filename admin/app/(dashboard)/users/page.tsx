'use client';

import { useEffect, useState, useCallback } from 'react';
import { Search, Filter, ShieldCheck, ShieldOff, ChevronLeft, ChevronRight } from 'lucide-react';
import { api } from '@/lib/api';
import { AdminUser } from '@/lib/types';

const VERIFICATION_LABELS: Record<string, { label: string; color: string }> = {
  UNVERIFIED: { label: 'Unverified', color: 'bg-slate-100 text-slate-600' },
  EMAIL_VERIFIED: { label: 'Email', color: 'bg-blue-100 text-blue-700' },
  COMPANY_VERIFIED: { label: 'Company', color: 'bg-indigo-100 text-indigo-700' },
  UNIVERSITY_VERIFIED: { label: 'University', color: 'bg-purple-100 text-purple-700' },
  LINKEDIN_VERIFIED: { label: 'LinkedIn', color: 'bg-sky-100 text-sky-700' },
  FULLY_VERIFIED: { label: 'Fully Verified', color: 'bg-green-100 text-green-700' },
};

const PAGE_SIZE = 15;

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [filterType, setFilterType] = useState('');
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/users', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: search || undefined,
          verificationStatus: filterStatus || undefined,
          userType: filterType || undefined,
        },
      });
      setUsers(res.data.data.users);
      setTotal(res.data.data.total);
    } catch {
      // keep existing data on error
    } finally {
      setLoading(false);
    }
  }, [page, search, filterStatus, filterType]);

  useEffect(() => { load(); }, [load]);

  async function toggleSuspend(user: AdminUser) {
    setActionLoading(user.id);
    try {
      await api.patch(`/admin/users/${user.id}/${user.isSuspended ? 'unsuspend' : 'suspend'}`);
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, isSuspended: !u.isSuspended } : u))
      );
    } finally {
      setActionLoading(null);
    }
  }

  const totalPages = Math.ceil(total / PAGE_SIZE);
  const initials = (u: AdminUser) =>
    `${u.firstName[0] ?? ''}${u.lastName[0] ?? ''}`.toUpperCase();

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Users</h1>
        <p className="text-slate-500 text-sm mt-1">{total} total users</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by name or email..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="w-full pl-9 pr-4 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div className="flex gap-2">
          <div className="relative">
            <Filter size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <select
              value={filterStatus}
              onChange={(e) => { setFilterStatus(e.target.value); setPage(1); }}
              className="pl-8 pr-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
            >
              <option value="">All Status</option>
              <option value="UNVERIFIED">Unverified</option>
              <option value="EMAIL_VERIFIED">Email Verified</option>
              <option value="COMPANY_VERIFIED">Company Verified</option>
              <option value="UNIVERSITY_VERIFIED">University Verified</option>
              <option value="FULLY_VERIFIED">Fully Verified</option>
            </select>
          </div>
          <select
            value={filterType}
            onChange={(e) => { setFilterType(e.target.value); setPage(1); }}
            className="px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
          >
            <option value="">All Types</option>
            <option value="PROFESSIONAL">Professional</option>
            <option value="STUDENT">Student</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="text-left px-4 py-3 font-semibold text-slate-600">User</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Type</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Verification</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Trust</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Joined</th>
                <th className="text-left px-4 py-3 font-semibold text-slate-600">Status</th>
                <th className="text-right px-4 py-3 font-semibold text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-slate-400">
                    <div className="flex justify-center">
                      <div className="w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
                    </div>
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-slate-400 text-sm">
                    No users found
                  </td>
                </tr>
              ) : (
                users.map((user) => {
                  const v = VERIFICATION_LABELS[user.verificationStatus] ?? VERIFICATION_LABELS.UNVERIFIED;
                  return (
                    <tr key={user.id} className="hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 font-semibold text-xs flex items-center justify-center shrink-0">
                            {initials(user)}
                          </div>
                          <div>
                            <p className="font-medium text-slate-900">
                              {user.firstName} {user.lastName}
                            </p>
                            <p className="text-xs text-slate-400">{user.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                          user.userType === 'PROFESSIONAL'
                            ? 'bg-blue-50 text-blue-700'
                            : 'bg-purple-50 text-purple-700'
                        }`}>
                          {user.userType === 'PROFESSIONAL' ? 'Professional' : 'Student'}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${v.color}`}>
                          {v.label}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="font-medium text-slate-700">{user.trustScore}</span>
                        <span className="text-slate-400">/100</span>
                      </td>
                      <td className="px-4 py-3 text-slate-500 text-xs">
                        {new Date(user.createdAt).toLocaleDateString('en-PK', {
                          day: 'numeric', month: 'short', year: 'numeric',
                        })}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                          user.isSuspended
                            ? 'bg-red-50 text-red-600'
                            : 'bg-green-50 text-green-700'
                        }`}>
                          {user.isSuspended ? 'Suspended' : 'Active'}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          onClick={() => toggleSuspend(user)}
                          disabled={actionLoading === user.id}
                          className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors disabled:opacity-50 ${
                            user.isSuspended
                              ? 'bg-green-50 hover:bg-green-100 text-green-700'
                              : 'bg-red-50 hover:bg-red-100 text-red-600'
                          }`}
                        >
                          {user.isSuspended ? (
                            <><ShieldCheck size={13} /> Unsuspend</>
                          ) : (
                            <><ShieldOff size={13} /> Suspend</>
                          )}
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-200">
            <p className="text-sm text-slate-500">
              {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, total)} of {total}
            </p>
            <div className="flex gap-1">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg hover:bg-slate-100 disabled:opacity-40 text-slate-600"
              >
                <ChevronLeft size={16} />
              </button>
              <span className="px-3 py-1.5 text-sm text-slate-700">
                {page} / {totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg hover:bg-slate-100 disabled:opacity-40 text-slate-600"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
