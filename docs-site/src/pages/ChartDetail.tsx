import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Check, ExternalLink, Maximize2, X } from 'lucide-react'
import { CodeBlock } from '../components/CodeBlock'
import { getChartById, chartCategories } from '../data/charts'

export function ChartDetail() {
  const { chartId } = useParams<{ chartId: string }>()
  const chart = getChartById(chartId || '')
  const [isFullscreen, setIsFullscreen] = useState(false)

  if (!chart) {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-4">Chart not found</h1>
          <Link to="/charts" className="text-primary-600 dark:text-primary-400 hover:underline">
            Back to Charts
          </Link>
        </div>
      </div>
    )
  }

  const category = chartCategories.find(c => c.id === chart.category)

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <Link
            to="/charts"
            className="inline-flex items-center text-sm text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 mb-4"
          >
            <ArrowLeft size={16} className="mr-1" />
            Back to Charts
          </Link>

          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-6">
            <div>
              <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 mb-3">
                {category?.label}
              </span>
              <h1 className="text-4xl font-bold text-slate-900 dark:text-white mb-4">
                {chart.title}
              </h1>
              <p className="text-lg text-slate-600 dark:text-slate-400 max-w-3xl">
                {chart.description}
              </p>
            </div>

            <div className="flex-shrink-0">
              <a
                href={`https://pub.dev/documentation/chartify/latest/chartify/${chart.id.replace('-', '_')}-library.html`}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700 transition-colors"
              >
                API Reference
                <ExternalLink size={14} />
              </a>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid lg:grid-cols-3 gap-12">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-12">
            {/* Live Preview */}
            <motion.section
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Live Preview</h2>
                <button
                  onClick={() => setIsFullscreen(true)}
                  className="inline-flex items-center gap-2 px-3 py-1.5 text-sm text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white bg-slate-100 dark:bg-slate-800 rounded-lg transition-colors"
                >
                  <Maximize2 size={16} />
                  Fullscreen
                </button>
              </div>
              <div className="chart-preview overflow-hidden" style={{ height: '500px' }}>
                <iframe
                  src={`/flutter-app/index.html#${chartId}`}
                  title={`${chart.title} Preview`}
                  className="w-full h-full border-0 rounded-lg"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope"
                />
              </div>
              <p className="text-sm text-slate-500 dark:text-slate-400 mt-3">
                This is the actual <strong>{chart.title}</strong> running in Flutter Web.
                The chart is fully interactive - try tapping, zooming, and panning!
              </p>
            </motion.section>

            {/* Fullscreen Modal */}
            {isFullscreen && (
              <div className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4">
                <button
                  onClick={() => setIsFullscreen(false)}
                  className="absolute top-4 right-4 p-2 text-white/80 hover:text-white bg-white/10 hover:bg-white/20 rounded-lg transition-colors"
                >
                  <X size={24} />
                </button>
                <iframe
                  src={`/flutter-app/index.html#${chartId}`}
                  title={`${chart.title} Preview - Fullscreen`}
                  className="w-full h-full max-w-6xl max-h-[90vh] border-0 rounded-xl"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope"
                />
              </div>
            )}

            {/* Code Example */}
            <motion.section
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-4">Code Example</h2>
              <p className="text-slate-600 dark:text-slate-400 mb-4">
                Copy and paste this code into your Flutter project to create a {chart.title.toLowerCase()}.
              </p>
              <CodeBlock
                code={chart.code}
                language="dart"
                filename={`${chart.id.replace(/-/g, '_')}_example.dart`}
              />
            </motion.section>

            {/* Usage Guide */}
            <motion.section
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-4">Usage Guide</h2>
              <div className="prose prose-slate dark:prose-invert max-w-none">
                <h3>Installation</h3>
                <p>
                  First, add Chartify to your <code>pubspec.yaml</code>:
                </p>
                <CodeBlock
                  code={`dependencies:
  chartify: ^0.1.0`}
                  language="yaml"
                  showLineNumbers={false}
                />

                <h3>Import</h3>
                <p>Import the library in your Dart file:</p>
                <CodeBlock
                  code={`import 'package:chartify/chartify.dart';`}
                  language="dart"
                  showLineNumbers={false}
                />

                <h3>Basic Setup</h3>
                <p>
                  The {chart.title} widget can be placed anywhere in your widget tree. It will
                  automatically size itself to fill its parent container, or you can wrap it in a
                  <code>SizedBox</code> to give it specific dimensions.
                </p>

                <h3>Customization</h3>
                <p>
                  Every aspect of the chart can be customized through the configuration objects.
                  Common customizations include:
                </p>
                <ul>
                  <li><strong>Colors:</strong> Use theme colors or custom colors for each series</li>
                  <li><strong>Animations:</strong> Control duration, curve, and delay of animations</li>
                  <li><strong>Tooltips:</strong> Customize content and appearance of interactive tooltips</li>
                  <li><strong>Axes:</strong> Configure labels, grid lines, and tick marks</li>
                  <li><strong>Legend:</strong> Position and style the chart legend</li>
                </ul>
              </div>
            </motion.section>
          </div>

          {/* Sidebar */}
          <div className="space-y-8">
            {/* Features */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="card p-6"
            >
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Features</h3>
              <ul className="space-y-3">
                {chart.features.map((feature, idx) => (
                  <li key={idx} className="flex items-start gap-3">
                    <div className="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                      <Check size={12} className="text-green-600 dark:text-green-400" />
                    </div>
                    <span className="text-slate-600 dark:text-slate-400 text-sm">{feature}</span>
                  </li>
                ))}
              </ul>
            </motion.div>

            {/* Related Charts */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
              className="card p-6"
            >
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Related Charts</h3>
              <div className="space-y-2">
                <Link
                  to="/charts"
                  className="block text-sm text-primary-600 dark:text-primary-400 hover:underline"
                >
                  View all {category?.label}
                </Link>
              </div>
            </motion.div>

            {/* Resources */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.5 }}
              className="card p-6"
            >
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Resources</h3>
              <ul className="space-y-3 text-sm">
                <li>
                  <a
                    href="https://pub.dev/packages/chartify"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary-600 dark:text-primary-400 hover:underline inline-flex items-center gap-1"
                  >
                    pub.dev Package
                    <ExternalLink size={12} />
                  </a>
                </li>
                <li>
                  <a
                    href="https://github.com/sitharaj88/chartify"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary-600 dark:text-primary-400 hover:underline inline-flex items-center gap-1"
                  >
                    GitHub Repository
                    <ExternalLink size={12} />
                  </a>
                </li>
                <li>
                  <Link
                    to="/examples"
                    className="text-primary-600 dark:text-primary-400 hover:underline"
                  >
                    More Examples
                  </Link>
                </li>
              </ul>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}
