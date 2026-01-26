import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown, Book, Rocket, Settings, Palette, Zap, MousePointer, MessageSquare, Award, Gauge, Paintbrush, Puzzle } from 'lucide-react'

interface SidebarItem {
  path: string
  label: string
  icon?: React.ReactNode
}

interface SidebarSection {
  title: string
  items: SidebarItem[]
  defaultOpen?: boolean
}

interface SidebarProps {
  sections: SidebarSection[]
}

const sectionIcons: Record<string, React.ReactNode> = {
  'Getting Started': <Rocket size={16} />,
  'Core Concepts': <Book size={16} />,
  'Customization': <Palette size={16} />,
  'Interactivity': <MousePointer size={16} />,
  'Advanced': <Settings size={16} />,
}

const itemIcons: Record<string, React.ReactNode> = {
  'Introduction': <Book size={14} />,
  'Installation': <Rocket size={14} />,
  'Quick Start': <Zap size={14} />,
  'Architecture': <Settings size={14} />,
  'Data Models': <Settings size={14} />,
  'Configuration': <Settings size={14} />,
  'Theming': <Palette size={14} />,
  'Animations': <Zap size={14} />,
  'Interactions': <MousePointer size={14} />,
  'Tooltips': <MessageSquare size={14} />,
  'Legends': <Award size={14} />,
  'Accessibility': <Award size={14} />,
  'Performance': <Gauge size={14} />,
  'Custom Painters': <Paintbrush size={14} />,
  'Plugins': <Puzzle size={14} />,
}

export function Sidebar({ sections }: SidebarProps) {
  const location = useLocation()
  const [openSections, setOpenSections] = useState<Set<string>>(() => {
    // Open the section containing the current page by default
    const initialOpen = new Set<string>()
    sections.forEach(section => {
      if (section.items.some(item => location.pathname === item.path) || section.defaultOpen) {
        initialOpen.add(section.title)
      }
    })
    // Always open first section
    if (sections.length > 0) {
      initialOpen.add(sections[0].title)
    }
    return initialOpen
  })

  const toggleSection = (title: string) => {
    setOpenSections(prev => {
      const next = new Set(prev)
      if (next.has(title)) {
        next.delete(title)
      } else {
        next.add(title)
      }
      return next
    })
  }

  return (
    <aside className="w-72 flex-shrink-0 hidden lg:block">
      <div className="sticky top-20 h-[calc(100vh-5rem)] overflow-y-auto pb-10 pr-4">
        {/* Search placeholder */}
        <div className="mb-6">
          <button className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600 transition-colors">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <span>Search docs...</span>
            <kbd className="ml-auto text-xs px-1.5 py-0.5 rounded bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400 font-mono">
              /
            </kbd>
          </button>
        </div>

        <nav className="space-y-2">
          {sections.map((section) => {
            const isOpen = openSections.has(section.title)
            const hasActiveItem = section.items.some(item => location.pathname === item.path)
            const SectionIcon = sectionIcons[section.title]

            return (
              <div key={section.title} className="mb-1">
                <button
                  onClick={() => toggleSection(section.title)}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                    hasActiveItem
                      ? 'text-slate-900 dark:text-white bg-slate-100 dark:bg-slate-800/50'
                      : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800/30'
                  }`}
                >
                  <span className="flex items-center gap-2">
                    {SectionIcon && <span className="text-slate-400 dark:text-slate-500">{SectionIcon}</span>}
                    {section.title}
                  </span>
                  <motion.span
                    animate={{ rotate: isOpen ? 180 : 0 }}
                    transition={{ duration: 0.2 }}
                  >
                    <ChevronDown size={16} className="text-slate-400" />
                  </motion.span>
                </button>

                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.ul
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2 }}
                      className="overflow-hidden"
                    >
                      <div className="ml-3 pl-3 mt-1 border-l border-slate-200 dark:border-slate-800 space-y-0.5">
                        {section.items.map(item => {
                          const isActive = location.pathname === item.path
                          const ItemIcon = itemIcons[item.label]

                          return (
                            <li key={item.path}>
                              <Link
                                to={item.path}
                                className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-all ${
                                  isActive
                                    ? 'text-primary-600 dark:text-primary-400 bg-primary-50 dark:bg-primary-900/20 font-medium'
                                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800/30'
                                }`}
                              >
                                {ItemIcon && (
                                  <span className={isActive ? 'text-primary-500' : 'text-slate-400 dark:text-slate-500'}>
                                    {ItemIcon}
                                  </span>
                                )}
                                {item.label}
                                {isActive && (
                                  <motion.div
                                    layoutId="sidebar-active-indicator"
                                    className="absolute left-0 w-0.5 h-6 bg-primary-600 dark:bg-primary-400 rounded-full"
                                  />
                                )}
                              </Link>
                            </li>
                          )
                        })}
                      </div>
                    </motion.ul>
                  )}
                </AnimatePresence>
              </div>
            )
          })}
        </nav>

        {/* Version badge */}
        <div className="mt-8 pt-6 border-t border-slate-200 dark:border-slate-800">
          <div className="flex items-center justify-between px-3 py-2 rounded-lg bg-slate-50 dark:bg-slate-800/50">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Version</span>
            <span className="text-xs font-mono font-medium text-primary-600 dark:text-primary-400 bg-primary-50 dark:bg-primary-900/30 px-2 py-0.5 rounded">
              v0.1.0
            </span>
          </div>
        </div>
      </div>
    </aside>
  )
}
