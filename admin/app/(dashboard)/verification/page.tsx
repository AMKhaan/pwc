'use client';

import { useEffect, useState, useCallback } from 'react';
import { ShieldCheck, ShieldX, Eye, ChevronLeft, ChevronRight, FileText, User, Calendar } from 'lucide-react';
import { api } from '@/lib/api';
import { AdminUser } from '@/lib/types';

const PAGE_SIZE = 15;

export default function VerificationPage() {
  const [items, setItems] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectInput, setShowRejectInput] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/verification-queue', {
        params: { page, limit: PAGE_SIZE },
      });
      setItems(res.data.data.items);
      setTotal(res.data.data.total);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => { load(); }, [load]);

  async function handleApprove(userId: string) {
    setActionLoading(`${userId}-approve`);
    try {
      await api.patch(`/admin/verification/${userId}/approve`);
      setItems((prev) => prev.filter((i) => i.id !== userId));
      setTotal((t) => t - 1);
      setSelectedUser(null);
    } finally {
      setActionLoading(null);
    }
  }

  async function handleReject(userId: string) {
    if (!rejectReason.trim()) return;
    setActionLoading(`${userId}-reject`);
    try {
      await api.patch(`/admin/verification/${userId}/reject`, { reason: rejectReason });
      setItems((prev) => prev.filter((i) => i.id !== userId));
      setTotal((t) => t - 1);
      setSelectedUser(null);
      setRejectReason('');
      setShowRejectInput(false);
    } finally {
      setActionLoading(null);
    }
  }

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Verification Queue</h1>
        <p className="text-slate-500 text-sm mt-1">{total} pending verifications</p>
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
                    <th className="text-left px-4 py-3 font-semibold text-slate-600">Submitted</th>
                    <th className="text-right px-4 py-3 font-semibold text-slate-600">Review</th>
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
                        onClick={() => { setSelectedUser(item); setShowRejectInput(false); setRejectReason(''); }}
                        className={`cursor-pointer transition-colors ${
                          selectedUser?.id === item.id ? 'bg-blue-50' : 'hover:bg-slate-50'
                        }`}
                      >
                        <td className="px-4 py-3">
                          <p className="font-medium text-slate-900">{item.firstName} {item.lastName}</p>
                          <p className="text-xs text-slate-400">{item.email}</p>
                        </td>
                        <td className="px-4 py-3">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                            item.userType === 'STUDENT'
                              ? 'bg-purple-100 text-purple-700'
                              : 'bg-blue-100 text-blue-700'
                          }`}>
                            {item.userType}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-500">
                          {item.verificationSubmittedAt
                            ? new Date(item.verificationSubmittedAt).toLocaleDateString()
                            : '—'}
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
              <div className="space-y-4">
                {/* Header */}
                <div className="flex items-center gap-3">
                  {selectedUser.avatarUrl ? (
                    <img src={selectedUser.avatarUrl} alt="avatar"
                      className="w-12 h-12 rounded-full object-cover border border-slate-200" />
                  ) : (
                    <div className="w-12 h-12 rounded-full bg-blue-100 text-blue-700 font-bold text-sm flex items-center justify-center">
                      {selectedUser.firstName[0]}{selectedUser.lastName[0]}
                    </div>
                  )}
                  <div>
                    <p className="font-semibold text-slate-900">{selectedUser.firstName} {selectedUser.lastName}</p>
                    <p className="text-xs text-slate-400">{selectedUser.email}</p>
                  </div>
                </div>

                {/* Basic info */}
                <div className="space-y-2 text-sm">
                  <Row label="Type" value={selectedUser.userType} />
                  {selectedUser.phone && <Row label="Phone" value={selectedUser.phone} />}
                  {selectedUser.officeName && <Row label="Office" value={selectedUser.officeName} />}
                  {selectedUser.universityName && <Row label="University" value={selectedUser.universityName} />}
                  {selectedUser.companyEmail && <Row label="Company Email" value={selectedUser.companyEmail} />}
                  {selectedUser.universityEmail && <Row label="University Email" value={selectedUser.universityEmail} />}
                  {selectedUser.linkedinUrl && (
                    <div className="flex justify-between">
                      <span className="text-slate-500">LinkedIn</span>
                      <a href={selectedUser.linkedinUrl} target="_blank" rel="noreferrer"
                        className="text-blue-600 hover:underline text-xs max-w-[160px] truncate">
                        View Profile
                      </a>
                    </div>
                  )}
                  {selectedUser.cnicNumber && <Row label="CNIC" value={selectedUser.cnicNumber} />}
                  {selectedUser.verificationSubmittedAt && (
                    <Row label="Submitted" value={new Date(selectedUser.verificationSubmittedAt).toLocaleString()} />
                  )}
                </div>

                {/* Documents */}
                {(selectedUser.cnicPhotoUrl || selectedUser.idCardPhotoUrl) && (
                  <div className="border-t border-slate-100 pt-4 space-y-3">
                    <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide flex items-center gap-1.5">
                      <FileText size={12} /> Documents
                    </p>
                    {selectedUser.cnicPhotoUrl && (
                      <DocImage label="CNIC Photo" url={selectedUser.cnicPhotoUrl} />
                    )}
                    {selectedUser.idCardPhotoUrl && (
                      <DocImage label="ID Card Photo" url={selectedUser.idCardPhotoUrl} />
                    )}
                  </div>
                )}

                {/* Actions */}
                <div className="border-t border-slate-100 pt-4 space-y-2">
                  {showRejectInput ? (
                    <>
                      <textarea
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                        placeholder="Reason for rejection..."
                        rows={3}
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm resize-none focus:outline-none focus:ring-2 focus:ring-red-400"
                      />
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleReject(selectedUser.id)}
                          disabled={!rejectReason.trim() || !!actionLoading}
                          className="flex-1 py-2.5 bg-red-600 hover:bg-red-700 disabled:opacity-60 text-white font-medium rounded-lg text-sm transition-colors"
                        >
                          {actionLoading === `${selectedUser.id}-reject` ? 'Rejecting...' : 'Confirm Reject'}
                        </button>
                        <button
                          onClick={() => { setShowRejectInput(false); setRejectReason(''); }}
                          className="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-600 font-medium rounded-lg text-sm transition-colors"
                        >
                          Cancel
                        </button>
                      </div>
                    </>
                  ) : (
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleApprove(selectedUser.id)}
                        disabled={!!actionLoading}
                        className="flex-1 flex items-center justify-center gap-1.5 py-2.5 bg-green-600 hover:bg-green-700 disabled:opacity-60 text-white font-medium rounded-lg text-sm transition-colors"
                      >
                        <ShieldCheck size={15} />
                        {actionLoading === `${selectedUser.id}-approve` ? 'Approving...' : 'Approve'}
                      </button>
                      <button
                        onClick={() => setShowRejectInput(true)}
                        disabled={!!actionLoading}
                        className="flex-1 flex items-center justify-center gap-1.5 py-2.5 bg-red-50 hover:bg-red-100 disabled:opacity-60 text-red-600 font-medium rounded-lg text-sm transition-colors"
                      >
                        <ShieldX size={15} />
                        Reject
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <span className="text-slate-500">{label}</span>
      <span className="font-medium text-slate-700 text-right max-w-[180px] truncate">{value}</span>
    </div>
  );
}

function DocImage({ label, url }: { label: string; url: string }) {
  return (
    <div>
      <p className="text-xs text-slate-500 mb-1">{label}</p>
      <a href={url} target="_blank" rel="noreferrer">
        <img src={url} alt={label}
          className="w-full h-32 object-cover rounded-lg border border-slate-200 hover:opacity-90 transition-opacity cursor-pointer" />
      </a>
    </div>
  );
}
