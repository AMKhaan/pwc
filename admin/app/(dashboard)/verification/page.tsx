'use client';

import { useEffect, useState, useCallback } from 'react';
import { api } from '@/lib/api';
import { AdminUser } from '@/lib/types';

const PAGE_SIZE = 20;

export default function VerificationPage() {
  const [items, setItems] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectModal, setRejectModal] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [toast, setToast] = useState<{ show: boolean; message: string; type: 'success' | 'error' }>({ show: false, message: '', type: 'success' });

  const quickReasons = [
    'CNIC photo is unclear. Please upload a clearer image.',
    'University ID photo is blurry or expired.',
    'Information does not match the uploaded document.',
    'Profile photo is missing or unclear.',
    'Incomplete information. Please fill all required fields.',
  ];

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/verification-queue', { params: { page, limit: PAGE_SIZE } });
      setItems(res.data.data.items);
      setTotal(res.data.data.total);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => { load(); }, [load]);

  function showToast(message: string, type: 'success' | 'error' = 'success') {
    setToast({ show: true, message, type });
    setTimeout(() => setToast(t => ({ ...t, show: false })), 3500);
  }

  async function handleApprove(user: AdminUser) {
    setActionLoading(true);
    try {
      await api.patch(`/admin/verification/${user.id}/approve`);
      showToast(`${user.firstName} approved successfully`);
      setItems(prev => prev.filter(i => i.id !== user.id));
      setTotal(t => t - 1);
      setSelectedUser(null);
    } catch (e: unknown) {
      showToast((e as { response?: { data?: { message?: string } } }).response?.data?.message || 'Error', 'error');
    } finally {
      setActionLoading(false);
    }
  }

  async function handleReject() {
    if (!selectedUser || !rejectReason.trim()) return;
    setActionLoading(true);
    try {
      await api.patch(`/admin/verification/${selectedUser.id}/reject`, { reason: rejectReason });
      showToast(`${selectedUser.firstName}'s verification declined`);
      setItems(prev => prev.filter(i => i.id !== selectedUser.id));
      setTotal(t => t - 1);
      setRejectModal(false);
      setSelectedUser(null);
      setRejectReason('');
    } catch (e: unknown) {
      showToast((e as { response?: { data?: { message?: string } } }).response?.data?.message || 'Error', 'error');
    } finally {
      setActionLoading(false);
    }
  }

  function timeAgo(dateStr?: string | null) {
    if (!dateStr) return '—';
    const diff = Date.now() - new Date(dateStr).getTime();
    const m = Math.floor(diff / 60000);
    if (m < 1) return 'just now';
    if (m < 60) return `${m}m ago`;
    const h = Math.floor(m / 60);
    if (h < 24) return `${h}h ago`;
    return `${Math.floor(h / 24)}d ago`;
  }

  function formatDate(dateStr?: string | null) {
    if (!dateStr) return '—';
    return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold text-gray-900">New Users</h2>
          <p className="text-gray-500 text-sm mt-0.5">Review and verify pending user accounts</p>
        </div>
        <button onClick={load}
          className="flex items-center gap-2 text-sm text-gray-600 hover:text-indigo-600 bg-white border border-gray-200 rounded-lg px-3 py-2 transition-colors">
          <svg className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh
        </button>
      </div>

      {/* Queue */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <svg className="animate-spin w-8 h-8 text-indigo-500" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
          </svg>
        </div>
      ) : items.length === 0 ? (
        <div className="text-center py-20">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-2xl mb-4">
            <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <p className="text-gray-500 font-medium">All caught up!</p>
          <p className="text-gray-400 text-sm mt-1">No pending verifications</p>
        </div>
      ) : (
        <div className="space-y-3">
          {items.map(u => (
            <div key={u.id}
              className="bg-white rounded-xl border border-gray-200 p-5 hover:border-indigo-200 hover:shadow-sm transition-all cursor-pointer"
              onClick={() => setSelectedUser(u)}>
              <div className="flex items-start gap-4">
                <div className="shrink-0">
                  {u.avatarUrl
                    ? <img src={u.avatarUrl} className="w-12 h-12 rounded-xl object-cover" alt="" />
                    : <div className="w-12 h-12 rounded-xl bg-indigo-500/10 flex items-center justify-center text-indigo-600 font-bold text-lg">
                        {u.firstName[0]}{u.lastName[0]}
                      </div>
                  }
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-semibold text-gray-900">{u.firstName} {u.lastName}</span>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${u.userType === 'PROFESSIONAL' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'}`}>
                      {u.userType}
                    </span>
                  </div>
                  <p className="text-gray-500 text-sm mt-0.5">{u.email}</p>
                  <div className="flex items-center gap-4 mt-2 text-xs text-gray-400 flex-wrap">
                    {u.userType === 'PROFESSIONAL' && u.officeName && (
                      <span>{u.officeName}</span>
                    )}
                    {u.userType === 'STUDENT' && u.universityName && (
                      <span>{u.universityName}</span>
                    )}
                    {u.verificationSubmittedAt ? (
                      <span className="flex items-center gap-1 text-green-600">
                        <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                        Profile submitted {timeAgo(u.verificationSubmittedAt)}
                      </span>
                    ) : (
                      <span className="text-amber-500">Profile not submitted yet</span>
                    )}
                    <span>Joined {formatDate(u.createdAt)}</span>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <button onClick={e => { e.stopPropagation(); handleApprove(u); }}
                    className="flex items-center gap-1.5 bg-green-500 text-white text-xs font-semibold px-3 py-1.5 rounded-lg hover:bg-green-600 transition-colors">
                    <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                    </svg>
                    Approve
                  </button>
                  <button onClick={e => { e.stopPropagation(); setSelectedUser(u); }}
                    className="text-xs font-medium text-gray-600 bg-gray-100 px-3 py-1.5 rounded-lg hover:bg-gray-200 transition-colors">
                    View Details
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Slide-over detail panel */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 flex">
          <div className="flex-1 bg-black/40" onClick={() => setSelectedUser(null)} />
          <div className="w-full max-w-lg bg-white h-full overflow-y-auto shadow-2xl flex flex-col animate-slide-in">
            {/* Header */}
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10">
              <div className="flex items-center gap-3">
                {selectedUser.avatarUrl
                  ? <img src={selectedUser.avatarUrl} className="w-10 h-10 rounded-xl object-cover" alt="" />
                  : <div className="w-10 h-10 rounded-xl bg-indigo-500/10 flex items-center justify-center text-indigo-600 font-bold">
                      {selectedUser.firstName[0]}{selectedUser.lastName[0]}
                    </div>
                }
                <div>
                  <p className="font-semibold text-gray-900">{selectedUser.firstName} {selectedUser.lastName}</p>
                  <p className="text-xs text-gray-400">{selectedUser.email}</p>
                </div>
              </div>
              <button onClick={() => setSelectedUser(null)} className="text-gray-400 hover:text-gray-600">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Body */}
            <div className="flex-1 px-6 py-5 space-y-6">
              <div className="flex items-center gap-2">
                <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${selectedUser.userType === 'PROFESSIONAL' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'}`}>
                  {selectedUser.userType}
                </span>
                <span className="text-xs text-gray-400">Submitted {timeAgo(selectedUser.verificationSubmittedAt)}</span>
              </div>

              {/* Professional fields */}
              {selectedUser.userType === 'PROFESSIONAL' && (
                <div className="space-y-4">
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Work Information</h3>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-gray-50 rounded-xl p-4">
                      <p className="text-xs text-gray-400 mb-1">Company</p>
                      <p className="font-medium text-gray-900 text-sm">{selectedUser.officeName || '—'}</p>
                    </div>
                    <div className="bg-gray-50 rounded-xl p-4">
                      <p className="text-xs text-gray-400 mb-1">CNIC Number</p>
                      <p className="font-medium text-gray-900 text-sm font-mono">{selectedUser.cnicNumber || '—'}</p>
                    </div>
                  </div>
                  {selectedUser.cnicPhotoUrl ? (
                    <div>
                      <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">CNIC Photo</h3>
                      <a href={selectedUser.cnicPhotoUrl} target="_blank" rel="noreferrer"
                        className="block rounded-xl overflow-hidden border border-gray-200 hover:opacity-90 transition-opacity">
                        <img src={selectedUser.cnicPhotoUrl} className="w-full h-44 object-cover" alt="CNIC" />
                        <div className="px-3 py-2 bg-gray-50 text-xs text-gray-400">Open full size</div>
                      </a>
                    </div>
                  ) : (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-xl px-4 py-3 text-sm text-yellow-700">No CNIC photo uploaded</div>
                  )}
                  {(selectedUser.linkedinUrl || selectedUser.officeLinkedinUrl) && (
                    <div>
                      <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">LinkedIn</h3>
                      {selectedUser.linkedinUrl && <a href={selectedUser.linkedinUrl} target="_blank" rel="noreferrer" className="text-blue-600 text-sm hover:underline block">Personal LinkedIn ↗</a>}
                      {selectedUser.officeLinkedinUrl && <a href={selectedUser.officeLinkedinUrl} target="_blank" rel="noreferrer" className="text-blue-600 text-sm hover:underline block mt-1">Company LinkedIn ↗</a>}
                    </div>
                  )}
                </div>
              )}

              {/* Student fields */}
              {selectedUser.userType === 'STUDENT' && (
                <div className="space-y-4">
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider">University Information</h3>
                  <div className="bg-gray-50 rounded-xl p-4">
                    <p className="text-xs text-gray-400 mb-1">University</p>
                    <p className="font-medium text-gray-900 text-sm">{selectedUser.universityName || '—'}</p>
                  </div>
                  {selectedUser.idCardPhotoUrl ? (
                    <div>
                      <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">University ID Card</h3>
                      <a href={selectedUser.idCardPhotoUrl} target="_blank" rel="noreferrer"
                        className="block rounded-xl overflow-hidden border border-gray-200 hover:opacity-90 transition-opacity">
                        <img src={selectedUser.idCardPhotoUrl} className="w-full h-44 object-cover" alt="ID Card" />
                        <div className="px-3 py-2 bg-gray-50 text-xs text-gray-400">Open full size</div>
                      </a>
                    </div>
                  ) : (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-xl px-4 py-3 text-sm text-yellow-700">No ID card photo uploaded</div>
                  )}
                </div>
              )}

              {/* Account info */}
              <div className="border-t border-gray-100 pt-4">
                <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Account</h3>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span className="text-gray-400">Phone</span>
                    <p className="text-gray-900 font-medium">{selectedUser.phone || '—'}</p>
                  </div>
                  <div>
                    <span className="text-gray-400">Status</span>
                    <p className={`font-medium ${selectedUser.isActive ? 'text-green-600' : 'text-red-500'}`}>
                      {selectedUser.isActive ? 'Active' : 'Inactive'}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Footer actions */}
            <div className="sticky bottom-0 bg-white border-t border-gray-200 p-4 flex gap-3">
              <button onClick={() => handleApprove(selectedUser)} disabled={actionLoading}
                className="flex-1 flex items-center justify-center gap-2 bg-green-500 text-white font-semibold py-3 rounded-xl hover:bg-green-600 transition-colors disabled:opacity-50">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                </svg>
                Approve
              </button>
              <button onClick={() => { setRejectModal(true); setRejectReason(''); }} disabled={actionLoading}
                className="flex-1 flex items-center justify-center gap-2 bg-red-500 text-white font-semibold py-3 rounded-xl hover:bg-red-600 transition-colors disabled:opacity-50">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" />
                </svg>
                Decline
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {rejectModal && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/50" onClick={() => setRejectModal(false)} />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <h3 className="text-lg font-bold text-gray-900 mb-1">Decline Verification</h3>
            <p className="text-gray-500 text-sm mb-4">This message will be shown to the user so they know what to fix.</p>
            <div className="flex flex-wrap gap-2 mb-3">
              {quickReasons.map(r => (
                <button key={r} onClick={() => setRejectReason(r)}
                  className={`text-xs border px-3 py-1.5 rounded-full transition-colors ${rejectReason === r ? 'bg-red-100 text-red-700 border-red-300' : 'bg-gray-100 text-gray-600 border-gray-200'}`}>
                  {r}
                </button>
              ))}
            </div>
            <textarea value={rejectReason} onChange={e => setRejectReason(e.target.value)} rows={4}
              className="w-full border border-gray-300 rounded-xl p-3 text-sm focus:outline-none focus:ring-2 focus:ring-red-400/50 resize-none"
              placeholder="e.g. Your CNIC photo is blurry..." />
            <div className="flex gap-3 mt-4">
              <button onClick={() => setRejectModal(false)}
                className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50">Cancel</button>
              <button onClick={handleReject} disabled={!rejectReason.trim() || actionLoading}
                className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-semibold hover:bg-red-600 disabled:opacity-50 flex items-center justify-center gap-2">
                {actionLoading && <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/></svg>}
                Send Decline Notice
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast.show && (
        <div className={`fixed bottom-6 right-6 z-[70] flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg text-sm font-medium ${toast.type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}`}>
          {toast.message}
        </div>
      )}
    </div>
  );
}
