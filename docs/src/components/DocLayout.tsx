import type { ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ChevronRight, ArrowLeft, ArrowRight, Clock, Calendar } from 'lucide-react'
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
  const allPages = getAllPages(sidebarSections)
  const currentIndex = allPages.findIndex(page => page.path === location.pathname)
  const prevPage = currentIndex > 0 ? allPages[currentIndex - 1] : null
  const nextPage = currentIndex < allPages.length - 1 ? allPages[currentIndex + 1] : null

  // Build breadcrumb
  const currentSection = sidebarSections.find(section =>
    section.items.some(item => item.path === location.pathname)
  )
  const currentPage = currentSection?.items.find(item => item.path === location.pathname)

  return (
    <div className="min-h-screen bg-white dark:bg-slate-950">
      <div className="max-w-[90rem] mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex gap-8 py-8">
          {/* Sidebar */}
          <Sidebar sections={sidebarSections} />

          {/* Main Content */}
          <main className="flex-1 min-w-0 max-w-3xl">
            {/* Breadcrumb */}
            <nav className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400 mb-8">
              <Link
                to="/docs"
                className="hover:text-slate-900 dark:hover:text-white transition-colors"
              >
                Docs
              </Link>
              {currentSection && (
                <>
                  <ChevronRight size={14} />
                  <span className="text-slate-400 dark:text-slate-500">
                    {currentSection.title}
                  </span>
                </>
              )}
              {currentPage && (
                <>
                  <ChevronRight size={14} />
                  <span className="text-slate-900 dark:text-white font-medium">
                    {currentPage.label}
                  </span>
                </>
              )}
            </nav>

            {/* Page Header */}
            <motion.header
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
              className="mb-10"
            >
              <h1 className="text-4xl font-bold text-slate-900 dark:text-white tracking-tight mb-4">
                {meta.title}
              </h1>
              {meta.description && (
                <p className="text-lg text-slate-600 dark:text-slate-400 leading-relaxed">
                  {meta.description}
                </p>
              )}
              {(meta.readingTime || meta.lastUpdated) && (
                <div className="flex items-center gap-4 mt-4 text-sm text-slate-500 dark:text-slate-400">
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
            <nav className="mt-16 pt-8 border-t border-slate-200 dark:border-slate-800">
              <div className="grid grid-cols-2 gap-4">
                {prevPage ? (
                  <Link
                    to={prevPage.path}
                    className="group flex flex-col items-start p-4 rounded-xl border border-slate-200 dark:border-slate-800 hover:border-primary-300 dark:hover:border-primary-700 hover:bg-slate-50 dark:hover:bg-slate-900/50 transition-all"
                  >
                    <span className="flex items-center gap-1 text-sm text-slate-500 dark:text-slate-400 mb-1">
                      <ArrowLeft size={14} />
                      Previous
                    </span>
                    <span className="font-medium text-slate-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                      {prevPage.label}
                    </span>
                  </Link>
                ) : (
                  <div />
                )}
                {nextPage ? (
                  <Link
                    to={nextPage.path}
                    className="group flex flex-col items-end p-4 rounded-xl border border-slate-200 dark:border-slate-800 hover:border-primary-300 dark:hover:border-primary-700 hover:bg-slate-50 dark:hover:bg-slate-900/50 transition-all"
                  >
                    <span className="flex items-center gap-1 text-sm text-slate-500 dark:text-slate-400 mb-1">
                      Next
                      <ArrowRight size={14} />
                    </span>
                    <span className="font-medium text-slate-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                      {nextPage.label}
                    </span>
                  </Link>
                ) : (
                  <div />
                )}
              </div>
            </nav>

            {/* Edit on GitHub */}
            <div className="mt-8 flex items-center justify-between text-sm text-slate-500 dark:text-slate-400">
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
                <h4 className="text-sm font-semibold text-slate-900 dark:text-white mb-4">
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
