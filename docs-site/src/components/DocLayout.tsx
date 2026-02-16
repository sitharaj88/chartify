import { useState } from 'react'
import type { ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronRight, ArrowLeft, ArrowRight, Clock, Calendar, Menu, X } from 'lucide-react'
import { Sidebar } from './Sidebar'

interface TOCItem {
  id: string
  text: string
  level: number
}

interface DocMeta {
  title: string
  description?: string
  readingTime?: string
  lastUpdated?: string
}

interface DocLayoutProps {
  children: ReactNode
  meta: DocMeta
  toc?: TOCItem[]
  sidebarSections: {
    title: string
    items: { path: string; label: string }[]
  }[]
}

// Flatten all pages for prev/next navigation
function getAllPages(sections: DocLayoutProps['sidebarSections']) {
  return sections.flatMap(section => section.items)
}

export function DocLayout({ children, meta, toc = [], sidebarSections }: DocLayoutProps) {
  const location = useLocation()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const allPages = getAllPages(sidebarSections)
  const currentIndex = allPages.findIndex(page => page.path === location.pathname)
  const prevPage = currentIndex > 0 ? allPages[currentIndex - 1] : null
  const nextPage = currentIndex < allPages.length - 1 ? allPages[currentIndex + 1] : null

  // Build breadcrumb
  const currentSection = sidebarSections.find(section =>
    section.items.some(item => item.path === location.pathname)
  )
  const currentPage = currentSection?.items.find(item => item.path === location.pathname)

  // Close mobile menu on route change
  const closeMobileMenu = () => setIsMobileMenuOpen(false)

  return (
    <div className="min-h-screen bg-white dark:bg-slate-950">
      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="fixed inset-0 bg-black/50 z-40 lg:hidden"
              onClick={closeMobileMenu}
            />
            {/* Drawer */}
            <motion.div
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="fixed inset-y-0 left-0 w-80 max-w-[calc(100vw-3rem)] bg-white dark:bg-slate-950 z-50 lg:hidden overflow-y-auto"
            >
              <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-800">
                <span className="text-lg font-semibold text-slate-800 dark:text-white">Documentation</span>
                <button
                  onClick={closeMobileMenu}
                  className="p-2 rounded-lg text-slate-500 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                >
                  <X size={20} />
                </button>
              </div>
              <div className="p-4">
                <Sidebar sections={sidebarSections} onNavigate={closeMobileMenu} mobile />
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <div className="max-w-[90rem] mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex gap-4 lg:gap-8 py-4 lg:py-8">
          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(true)}
            className="lg:hidden fixed bottom-6 right-6 z-30 p-4 bg-primary-600 text-white rounded-full shadow-lg hover:bg-primary-700 transition-colors"
          >
            <Menu size={24} />
          </button>

          {/* Desktop Sidebar */}
          <Sidebar sections={sidebarSections} />

          {/* Main Content */}
          <main className="flex-1 min-w-0 lg:max-w-3xl">
            {/* Breadcrumb */}
            <nav className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400 mb-6 lg:mb-8 overflow-x-auto">
              <Link
                to="/docs"
                className="hover:text-slate-900 dark:hover:text-white transition-colors whitespace-nowrap"
              >
                Docs
              </Link>
              {currentSection && (
                <>
                  <ChevronRight size={14} className="flex-shrink-0" />
                  <span className="text-slate-400 dark:text-slate-500 hidden sm:inline whitespace-nowrap">
                    {currentSection.title}
                  </span>
                </>
              )}
              {currentPage && (
                <>
                  <ChevronRight size={14} className="flex-shrink-0 hidden sm:inline" />
                  <span className="text-slate-800 dark:text-white font-medium whitespace-nowrap">
                    {currentPage.label}
                  </span>
                </>
              )}
            </nav>

            {/* Mobile TOC */}
            {toc.length > 0 && (
              <div className="xl:hidden mb-6 p-4 rounded-xl bg-indigo-50/30 dark:bg-slate-900/50 border border-indigo-100/60 dark:border-slate-800">
                <details className="group">
                  <summary className="flex items-center justify-between cursor-pointer text-sm font-semibold text-slate-800 dark:text-white">
                    <span>On this page</span>
                    <ChevronRight size={16} className="transform transition-transform group-open:rotate-90" />
                  </summary>
                  <nav className="mt-3 text-sm">
                    <ul className="space-y-2 border-l border-slate-200 dark:border-slate-700">
                      {toc.map((item) => (
                        <li key={item.id}>
                          <a
                            href={`#${item.id}`}
                            className={`block py-1 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors ${
                              item.level === 2 ? 'pl-4' : 'pl-8'
                            }`}
                          >
                            {item.text}
                          </a>
                        </li>
                      ))}
                    </ul>
                  </nav>
                </details>
              </div>
            )}

            {/* Page Header */}
            <motion.header
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
              className="mb-8 lg:mb-10"
            >
              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-800 dark:text-white tracking-tight mb-3 lg:mb-4">
                {meta.title}
              </h1>
              {meta.description && (
                <p className="text-base lg:text-lg text-slate-600 dark:text-slate-400 leading-relaxed">
                  {meta.description}
                </p>
              )}
              {(meta.readingTime || meta.lastUpdated) && (
                <div className="flex flex-wrap items-center gap-3 lg:gap-4 mt-3 lg:mt-4 text-sm text-slate-500 dark:text-slate-400">
                  {meta.readingTime && (
                    <span className="flex items-center gap-1.5">
                      <Clock size={14} />
                      {meta.readingTime}
                    </span>
                  )}
                  {meta.lastUpdated && (
                    <span className="flex items-center gap-1.5">
                      <Calendar size={14} />
                      Updated {meta.lastUpdated}
                    </span>
                  )}
                </div>
              )}
            </motion.header>

            {/* Content */}
            <motion.article
              key={location.pathname}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.1 }}
              className="prose prose-slate dark:prose-invert max-w-none"
            >
              {children}
            </motion.article>

            {/* Prev/Next Navigation */}
            <nav className="mt-10 lg:mt-16 pt-6 lg:pt-8 border-t border-slate-200 dark:border-slate-800">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
                {prevPage ? (
                  <Link
                    to={prevPage.path}
                    className="group flex flex-col items-start p-3 sm:p-4 rounded-xl border border-indigo-100/60 dark:border-slate-800 hover:border-primary-200 dark:hover:border-primary-700 hover:bg-indigo-50/30 dark:hover:bg-slate-900/50 shadow-sm shadow-indigo-500/5 dark:shadow-none transition-all"
                  >
                    <span className="flex items-center gap-1 text-sm text-slate-500 dark:text-slate-400 mb-1">
                      <ArrowLeft size={14} />
                      Previous
                    </span>
                    <span className="font-medium text-slate-800 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                      {prevPage.label}
                    </span>
                  </Link>
                ) : (
                  <div className="hidden sm:block" />
                )}
                {nextPage ? (
                  <Link
                    to={nextPage.path}
                    className="group flex flex-col items-start sm:items-end p-3 sm:p-4 rounded-xl border border-indigo-100/60 dark:border-slate-800 hover:border-primary-200 dark:hover:border-primary-700 hover:bg-indigo-50/30 dark:hover:bg-slate-900/50 shadow-sm shadow-indigo-500/5 dark:shadow-none transition-all"
                  >
                    <span className="flex items-center gap-1 text-sm text-slate-500 dark:text-slate-400 mb-1">
                      Next
                      <ArrowRight size={14} />
                    </span>
                    <span className="font-medium text-slate-800 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                      {nextPage.label}
                    </span>
                  </Link>
                ) : (
                  <div className="hidden sm:block" />
                )}
              </div>
            </nav>

            {/* Edit on GitHub */}
            <div className="mt-6 lg:mt-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 text-sm text-slate-500 dark:text-slate-400">
              <a
                href="#"
                className="hover:text-slate-900 dark:hover:text-white transition-colors"
              >
                Edit this page on GitHub
              </a>
              <span>Was this page helpful?</span>
            </div>
          </main>

          {/* Table of Contents */}
          {toc.length > 0 && (
            <aside className="hidden xl:block w-56 flex-shrink-0">
              <div className="sticky top-24">
                <h4 className="text-sm font-semibold text-slate-800 dark:text-white mb-4">
                  On this page
                </h4>
                <nav className="text-sm">
                  <ul className="space-y-2 border-l border-slate-200 dark:border-slate-800">
                    {toc.map((item) => (
                      <li key={item.id}>
                        <a
                          href={`#${item.id}`}
                          className={`block py-1 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors ${
                            item.level === 2 ? 'pl-4' : 'pl-8'
                          }`}
                        >
                          {item.text}
                        </a>
                      </li>
                    ))}
                  </ul>
                </nav>
              </div>
            </aside>
          )}
        </div>
      </div>
    </div>
  )
}
