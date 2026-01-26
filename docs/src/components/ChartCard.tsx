import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'

interface ChartCardProps {
  title: string
  description: string
  icon: React.ReactNode
  path: string
  category: string
}

export function ChartCard({ title, description, icon, path, category }: ChartCardProps) {
  return (
    <motion.div
      whileHover={{ y: -4 }}
      transition={{ duration: 0.2 }}
    >
      <Link
        to={path}
        className="block card p-6 h-full hover:border-primary-300 dark:hover:border-primary-700 transition-colors"
      >
        <div className="flex items-start space-x-4">
          <div className="flex-shrink-0 w-12 h-12 bg-primary-100 dark:bg-primary-900/30 rounded-lg flex items-center justify-center text-primary-600 dark:text-primary-400">
            {icon}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-medium text-primary-600 dark:text-primary-400 uppercase tracking-wide mb-1">
              {category}
            </p>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2">
              {title}
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-400 line-clamp-2">
              {description}
            </p>
          </div>
        </div>
      </Link>
    </motion.div>
  )
}
