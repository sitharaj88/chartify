import { useState } from 'react'
import { motion } from 'framer-motion'
import { Search, BarChart3, PieChart, GitBranch, Activity, Gauge, TrendingUp } from 'lucide-react'
import { ChartCard } from '../components/ChartCard'
import { charts, chartCategories } from '../data/charts'

const categoryIcons: Record<string, React.ReactNode> = {
  cartesian: <BarChart3 size={20} />,
  circular: <PieChart size={20} />,
  hierarchical: <GitBranch size={20} />,
  statistical: <Activity size={20} />,
  specialty: <Gauge size={20} />,
  financial: <TrendingUp size={20} />,
}

export function Charts() {
  const [search, setSearch] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)

  const filteredCharts = charts.filter(chart => {
    const matchesSearch = search === '' ||
      chart.title.toLowerCase().includes(search.toLowerCase()) ||
      chart.description.toLowerCase().includes(search.toLowerCase())
    const matchesCategory = selectedCategory === null || chart.category === selectedCategory
    return matchesSearch && matchesCategory
  })

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <h1 className="text-4xl font-bold text-slate-900 dark:text-white mb-4">
            Chart Gallery
          </h1>
          <p className="text-lg text-slate-600 dark:text-slate-400 max-w-3xl">
            Explore all 25+ chart types available in Chartify. Each chart includes interactive examples,
            complete code snippets, and API documentation.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Search and Filters */}
        <div className="flex flex-col lg:flex-row gap-4 mb-8">
          {/* Search */}
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
            <input
              type="text"
              placeholder="Search charts..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            />
          </div>

          {/* Category Filters */}
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => setSelectedCategory(null)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                selectedCategory === null
                  ? 'bg-primary-600 text-white'
                  : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 border border-slate-200 dark:border-slate-700'
              }`}
            >
              All Charts
            </button>
            {chartCategories.map(cat => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  selectedCategory === cat.id
                    ? 'bg-primary-600 text-white'
                    : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 border border-slate-200 dark:border-slate-700'
                }`}
              >
                {categoryIcons[cat.id]}
                {cat.label}
              </button>
            ))}
          </div>
        </div>

        {/* Results Count */}
        <p className="text-sm text-slate-500 dark:text-slate-400 mb-6">
          Showing {filteredCharts.length} of {charts.length} charts
        </p>

        {/* Chart Grid */}
        <motion.div
          layout
          className="grid md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {filteredCharts.map((chart, idx) => (
            <motion.div
              key={chart.id}
              layout
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: idx * 0.05 }}
            >
              <ChartCard
                title={chart.title}
                description={chart.description}
                icon={categoryIcons[chart.category]}
                path={`/charts/${chart.id}`}
                category={chartCategories.find(c => c.id === chart.category)?.label || chart.category}
              />
            </motion.div>
          ))}
        </motion.div>

        {filteredCharts.length === 0 && (
          <div className="text-center py-16">
            <p className="text-slate-500 dark:text-slate-400">
              No charts found matching your search criteria.
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
