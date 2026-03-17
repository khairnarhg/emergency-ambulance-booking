import type { LucideIcon } from 'lucide-react';
import type { ReactNode } from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color: string;
  className?: string;
  children?: ReactNode;
}

export default function StatCard({ title, value, icon: Icon, color, className = '', children }: StatCardProps) {
  return (
    <div className={`bg-white rounded-lg shadow-sm border border-gray-100 p-5 ${className}`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{title}</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
        </div>
        <div className={`w-11 h-11 rounded-lg flex items-center justify-center ${color}`}>
          <Icon size={22} className="text-white" />
        </div>
      </div>
      {children}
    </div>
  );
}
