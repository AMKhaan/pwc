'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/sidebar';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();

  useEffect(() => {
    if (typeof window !== 'undefined' && !localStorage.getItem('admin_token')) {
      router.replace('/login');
    }
  }, [router]);

  return (
    <div className="min-h-screen flex bg-gray-50">
      <Sidebar />
      <main className="ml-56 flex-1 p-6 overflow-auto">
        {children}
      </main>
    </div>
  );
}
