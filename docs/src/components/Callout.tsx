import type { ReactNode } from 'react'
import { Info, AlertTriangle, Lightbulb, AlertCircle, CheckCircle2 } from 'lucide-react'

type CalloutType = 'info' | 'warning' | 'tip' | 'danger' | 'success'

interface CalloutProps {
  type?: CalloutType
  title?: string
  children: ReactNode
}

const calloutConfig = {
  info: {
    icon: Info,
    bgColor: 'bg-blue-50 dark:bg-blue-950/30',
    borderColor: 'border-blue-200 dark:border-blue-800',
    iconColor: 'text-blue-600 dark:text-blue-400',
    titleColor: 'text-blue-900 dark:text-blue-200',
    textColor: 'text-blue-800 dark:text-blue-300',
    defaultTitle: 'Note',
  },
  warning: {
    icon: AlertTriangle,
    bgColor: 'bg-amber-50 dark:bg-amber-950/30',
    borderColor: 'border-amber-200 dark:border-amber-800',
    iconColor: 'text-amber-600 dark:text-amber-400',
    titleColor: 'text-amber-900 dark:text-amber-200',
    textColor: 'text-amber-800 dark:text-amber-300',
    defaultTitle: 'Warning',
  },
  tip: {
    icon: Lightbulb,
    bgColor: 'bg-emerald-50 dark:bg-emerald-950/30',
    borderColor: 'border-emerald-200 dark:border-emerald-800',
    iconColor: 'text-emerald-600 dark:text-emerald-400',
    titleColor: 'text-emerald-900 dark:text-emerald-200',
    textColor: 'text-emerald-800 dark:text-emerald-300',
    defaultTitle: 'Tip',
  },
  danger: {
    icon: AlertCircle,
    bgColor: 'bg-red-50 dark:bg-red-950/30',
    borderColor: 'border-red-200 dark:border-red-800',
    iconColor: 'text-red-600 dark:text-red-400',
    titleColor: 'text-red-900 dark:text-red-200',
    textColor: 'text-red-800 dark:text-red-300',
    defaultTitle: 'Danger',
  },
  success: {
    icon: CheckCircle2,
    bgColor: 'bg-green-50 dark:bg-green-950/30',
    borderColor: 'border-green-200 dark:border-green-800',
    iconColor: 'text-green-600 dark:text-green-400',
    titleColor: 'text-green-900 dark:text-green-200',
    textColor: 'text-green-800 dark:text-green-300',
    defaultTitle: 'Success',
  },
}

export function Callout({ type = 'info', title, children }: CalloutProps) {
  const config = calloutConfig[type]
  const Icon = config.icon
  const displayTitle = title || config.defaultTitle

  return (
    <div className={`my-6 rounded-xl border ${config.bgColor} ${config.borderColor} p-4`}>
      <div className="flex gap-3">
        <div className={`flex-shrink-0 ${config.iconColor}`}>
          <Icon size={20} />
        </div>
        <div className="flex-1 min-w-0">
          <p className={`font-semibold text-sm ${config.titleColor} mb-1`}>
            {displayTitle}
          </p>
          <div className={`text-sm ${config.textColor} [&>p]:m-0 [&>p:not(:last-child)]:mb-2`}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
