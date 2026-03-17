import { Check } from 'lucide-react';
import type { SosStatus } from '../../types/index.ts';
import { getSosTimeline, sosStatusLabel } from '../../utils/parseStatus.ts';

interface StatusTimelineProps {
  currentStatus: SosStatus;
}

export default function StatusTimeline({ currentStatus }: StatusTimelineProps) {
  const steps = getSosTimeline(currentStatus);

  return (
    <div className="flex items-center gap-1 overflow-x-auto py-2">
      {steps.map((step, i) => (
        <div key={step.status} className="flex items-center">
          <div className="flex flex-col items-center">
            <div
              className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-medium shrink-0 ${
                step.active
                  ? 'bg-primary-600 text-white ring-2 ring-primary-200'
                  : step.reached
                  ? 'bg-green-500 text-white'
                  : 'bg-gray-200 text-gray-500'
              }`}
            >
              {step.reached && !step.active ? <Check size={14} /> : i + 1}
            </div>
            <span
              className={`text-[10px] mt-1 text-center max-w-[70px] leading-tight ${
                step.active ? 'text-primary-700 font-semibold' : step.reached ? 'text-green-700' : 'text-gray-400'
              }`}
            >
              {sosStatusLabel(step.status)}
            </span>
          </div>
          {i < steps.length - 1 && (
            <div
              className={`h-0.5 w-6 mx-0.5 mt-[-14px] ${
                step.reached ? 'bg-green-400' : 'bg-gray-200'
              }`}
            />
          )}
        </div>
      ))}
    </div>
  );
}
