import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowRight, Zap, Layers, Smartphone, Palette, Code2, BarChart3, Sparkles, Github } from 'lucide-react'
import { CodeBlock } from '../components/CodeBlock'

const features = [
  {
    icon: <BarChart3 size={24} />,
    title: '32+ Chart Types',
    description: 'Line, bar, pie, scatter, treemap, sankey, gauge, candlestick, and many more chart types ready to use.',
  },
  {
    icon: <Zap size={24} />,
    title: 'High Performance',
    description: 'Optimized rendering with viewport culling, spatial indexing, and efficient memory management for large datasets.',
  },
  {
    icon: <Layers size={24} />,
    title: 'Clean Architecture',
    description: 'Built with SOLID principles, modular design, and comprehensive TypeScript-like Dart typing for maintainability.',
  },
  {
    icon: <Smartphone size={24} />,
    title: 'Cross-Platform',
    description: 'Works seamlessly on iOS, Android, web, desktop (Windows, macOS, Linux) with responsive touch interactions.',
  },
  {
    icon: <Palette size={24} />,
    title: 'Fully Customizable',
    description: 'Extensive theming support, custom painters, animations, and style configurations for any design requirement.',
  },
  {
    icon: <Code2 size={24} />,
    title: 'Developer Friendly',
    description: 'Intuitive API, comprehensive documentation, code examples, and excellent IDE autocompletion support.',
  },
]

const quickStartCode = `import 'package:chartify/chartify.dart';

class MyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      series: [
        LineSeries(
          name: 'Sales',
          data: [
            DataPoint(x: 1, y: 30),
            DataPoint(x: 2, y: 45),
            DataPoint(x: 3, y: 28),
            DataPoint(x: 4, y: 65),
            DataPoint(x: 5, y: 52),
          ],
          color: Colors.blue,
          curved: true,
        ),
      ],
      config: ChartConfig(
        title: ChartTitle(text: 'Monthly Sales'),
        tooltip: TooltipConfig(enabled: true),
      ),
    );
  }
}`

export function Home() {
  return (
    <div>
      {/* Hero Section */}
      <section className="relative overflow-hidden hero-gradient pt-16 pb-24 sm:pt-24 sm:pb-32">
        {/* Background decoration */}
        <div className="absolute inset-0 dot-pattern opacity-30" />
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[800px] bg-gradient-to-b from-primary-500/20 to-transparent rounded-full blur-3xl" />

        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            {/* Badge */}
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.4, delay: 0.1 }}
            >
              <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm text-primary-700 dark:text-primary-300 border border-primary-200 dark:border-primary-800 shadow-sm mb-8">
                <Sparkles size={16} className="text-amber-500" />
                v1.0.0 - Now Available on pub.dev
              </span>
            </motion.div>

            {/* Headline */}
            <h1 className="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-bold text-slate-900 dark:text-white mb-6 tracking-tight">
              Beautiful Charts for
              <span className="block mt-2 gradient-text">Flutter Apps</span>
            </h1>

            {/* Subheadline */}
            <p className="text-lg sm:text-xl text-slate-600 dark:text-slate-400 max-w-3xl mx-auto mb-10 leading-relaxed">
              A comprehensive, high-performance chart library supporting 32+ chart types,
              large datasets, and cross-platform compatibility. Built for production.
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <Link to="/docs" className="btn-primary">
                  Get Started
                  <ArrowRight size={18} />
                </Link>
              </motion.div>
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <Link to="/charts" className="btn-secondary">
                  Browse Charts
                </Link>
              </motion.div>
            </div>

            {/* Quick install */}
            <div className="mt-10 inline-flex items-center gap-3 px-4 py-2.5 rounded-xl bg-slate-900 dark:bg-slate-800 text-slate-300 font-mono text-sm">
              <span className="text-slate-500">$</span>
              <span>flutter pub add chartify</span>
              <button
                onClick={() => navigator.clipboard.writeText('flutter pub add chartify')}
                className="ml-2 p-1.5 rounded-lg hover:bg-slate-700 transition-colors"
                title="Copy to clipboard"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </button>
            </div>
          </motion.div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-6 lg:gap-8"
          >
            {[
              { value: '32+', label: 'Chart Types', color: 'from-blue-500 to-cyan-500' },
              { value: '10K+', label: 'Data Points', color: 'from-purple-500 to-pink-500' },
              { value: '60fps', label: 'Performance', color: 'from-amber-500 to-orange-500' },
              { value: '6', label: 'Platforms', color: 'from-emerald-500 to-teal-500' },
            ].map((stat, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.4 + idx * 0.1 }}
                className="relative p-6 rounded-2xl bg-white dark:bg-slate-800/60 backdrop-blur-sm border border-indigo-100 dark:border-slate-700/50 shadow-sm shadow-indigo-500/5 dark:shadow-none text-center"
              >
                <div className={`text-4xl lg:text-5xl font-bold bg-gradient-to-r ${stat.color} bg-clip-text text-transparent`}>
                  {stat.value}
                </div>
                <div className="text-sm text-slate-600 dark:text-slate-400 mt-2 font-medium">{stat.label}</div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Live Demo Section */}
      <section className="py-20 bg-slate-50/50 dark:bg-slate-950">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <span className="badge mb-4">Interactive Demo</span>
            <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
              Try It Live
            </h2>
            <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
              Explore all chart types in this interactive demo. Tap, zoom, pan, and interact with real data.
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            viewport={{ once: true }}
            className="card overflow-hidden shadow-2xl shadow-indigo-500/10 dark:shadow-none"
            style={{ height: '600px' }}
          >
            <iframe
              src={`${import.meta.env.BASE_URL}flutter-app/index.html`}
              title="Chartify Live Demo"
              className="w-full h-full border-0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope"
            />
          </motion.div>
          <p className="text-center text-sm text-slate-500 dark:text-slate-400 mt-4">
            This is the actual Flutter app running in your browser. Swipe through different chart types!
          </p>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24 bg-gradient-to-b from-white to-slate-50 dark:from-slate-950 dark:to-slate-900/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <span className="badge mb-4">Features</span>
            <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
              Everything You Need
            </h2>
            <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
              Chartify provides all the tools you need to create stunning, interactive data visualizations.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8">
            {features.map((feature, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: idx * 0.1 }}
                viewport={{ once: true }}
                className="group card p-6 hover:border-primary-200 dark:hover:border-primary-700"
              >
                <div className="w-12 h-12 bg-gradient-to-br from-primary-50 to-primary-100 dark:from-primary-900/50 dark:to-primary-800/50 rounded-xl flex items-center justify-center text-primary-600 dark:text-primary-400 mb-4 group-hover:scale-110 transition-transform ring-1 ring-primary-200/50 dark:ring-0">
                  {feature.icon}
                </div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2">
                  {feature.title}
                </h3>
                <p className="text-slate-600 dark:text-slate-400 leading-relaxed">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Quick Start Section */}
      <section className="py-24 bg-slate-50 dark:bg-slate-950">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5 }}
              viewport={{ once: true }}
            >
              <span className="badge mb-4">Quick Start</span>
              <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
                Get Started in Minutes
              </h2>
              <p className="text-lg text-slate-600 dark:text-slate-400 mb-8">
                Add Chartify to your Flutter project and start creating beautiful charts with just a few lines of code.
              </p>

              <div className="space-y-6">
                {[
                  { step: 1, title: 'Add dependency', code: 'flutter pub add chartify' },
                  { step: 2, title: 'Import the library', code: "import 'package:chartify/chartify.dart';" },
                  { step: 3, title: 'Create your first chart', desc: 'Use any of the 32+ chart widgets' },
                ].map(({ step, title, code, desc }) => (
                  <div key={step} className="flex items-start gap-4">
                    <div className="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-600 text-white rounded-xl flex items-center justify-center text-sm font-bold shadow-lg shadow-primary-500/25">
                      {step}
                    </div>
                    <div>
                      <h4 className="font-semibold text-slate-900 dark:text-white">{title}</h4>
                      {code ? (
                        <code className="text-sm text-primary-600 dark:text-primary-400 font-mono">{code}</code>
                      ) : (
                        <p className="text-sm text-slate-600 dark:text-slate-400">{desc}</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <Link
                to="/docs"
                className="inline-flex items-center gap-2 mt-8 text-primary-600 dark:text-primary-400 font-medium hover:underline"
              >
                Read the full documentation
                <ArrowRight size={16} />
              </Link>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              viewport={{ once: true }}
            >
              <CodeBlock
                code={quickStartCode}
                language="dart"
                filename="my_chart.dart"
              />
            </motion.div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-r from-primary-600 via-primary-700 to-indigo-700" />
        <div className="absolute inset-0 dot-pattern opacity-10" />

        <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
          >
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-6">
              Ready to Build Something Amazing?
            </h2>
            <p className="text-xl text-white/80 mb-10 max-w-2xl mx-auto">
              Start creating beautiful, interactive charts for your Flutter applications today.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <Link
                  to="/docs"
                  className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-xl bg-white text-primary-600 font-semibold hover:bg-slate-100 transition-colors shadow-xl shadow-black/10"
                >
                  Get Started Free
                  <ArrowRight size={18} />
                </Link>
              </motion.div>
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <a
                  href="https://github.com/sitharaj88/chartify"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-xl border-2 border-white/30 text-white font-semibold hover:bg-white/10 transition-colors"
                >
                  <Github size={20} />
                  View on GitHub
                </a>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  )
}
