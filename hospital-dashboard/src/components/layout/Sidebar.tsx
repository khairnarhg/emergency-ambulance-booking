import { NavLink } from 'react-router-dom';
import {
  Home,
  AlertTriangle,
  Map,
  Truck,
  Users,
  BarChart3,
  Bell,
  ChevronLeft,
  ChevronRight,
  UserSearch,
} from 'lucide-react';
import { useNotificationStore } from '../../store/notificationStore.ts';

const navItems = [
  { to: '/', icon: Home, label: 'Dashboard' },
  { to: '/sos', icon: AlertTriangle, label: 'SOS Monitor' },
  { to: '/map', icon: Map, label: 'Live Map' },
  { to: '/ambulances', icon: Truck, label: 'Ambulances' },
  { to: '/staff', icon: Users, label: 'Staff' },
  { to: '/analytics', icon: BarChart3, label: 'Analytics' },
  { to: '/notifications', icon: Bell, label: 'Notifications' },
  { to: '/patients', icon: UserSearch, label: 'Patients' },
];

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

export default function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const unreadCount = useNotificationStore((s) => s.unreadCount);

  return (
    <aside
      className={`fixed left-0 top-16 bottom-0 z-30 bg-white border-r border-gray-200 flex flex-col transition-all duration-200 ease-in-out ${
        collapsed ? 'w-[72px]' : 'w-64'
      }`}
    >
      <nav className="flex-1 py-4 space-y-1 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-2.5 mx-2 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary-50 text-primary-700'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`
            }
          >
            <div className="relative shrink-0">
              <Icon size={20} />
              {label === 'Notifications' && unreadCount > 0 && (
                <span className="absolute -top-1.5 -right-1.5 bg-red-500 text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
                  {unreadCount > 99 ? '99+' : unreadCount}
                </span>
              )}
            </div>
            {!collapsed && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>
      <button
        onClick={onToggle}
        className="flex items-center justify-center py-3 border-t border-gray-200 text-gray-400 hover:text-gray-600 transition-colors"
      >
        {collapsed ? <ChevronRight size={20} /> : <ChevronLeft size={20} />}
      </button>
    </aside>
  );
}
