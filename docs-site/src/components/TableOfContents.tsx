import { useState, useEffect } from 'react'
import { List } from 'lucide-react'

interface TOCItem {
  id: string
  text: string
  level: number
}

interface TableOfContentsProps {
  items: TOCItem[]
}

export function TableOfContents({ items }: TableOfContentsProps) {
  const [activeId, setActiveId] = useState<string>('')

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveId(entry.target.id)
          }
        })
      },
      {
        rootMargin: '-80px 0px -80% 0px',
        threshold: 0,
      }
    )

    items.forEach(({ id }) => {
      const element = document.getElementById(id)
      if (element) {
        observer.observe(element)
      }
    })

    return () => observer.disconnect()
  }, [items])

  const handleClick = (id: string) => {
    const element = document.getElementById(id)
    if (element) {
      const offset = 100
      const elementPosition = element.getBoundingClientRect().top
      const offsetPosition = elementPosition + window.pageYOffset - offset
      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth',
      })
    }
  }

  if (items.length === 0) return null

  return (
    <nav className="hidden xl:block w-64 flex-shrink-0">
      <div className="sticky top-24">
        <div className="flex items-center gap-2 text-sm font-semibold text-slate-800 dark:text-white mb-4">
          <List size={16} />
          On this page
        </div>
        <ul className="space-y-2 text-sm border-l border-slate-200 dark:border-slate-800">
          {items.map((item) => (
            <li key={item.id}>
              <button
                onClick={() => handleClick(item.id)}
                className={`block w-full text-left py-1 transition-colors ${
                  item.level === 2 ? 'pl-4' : 'pl-8'
                } ${
                  activeId === item.id
                    ? 'text-primary-600 dark:text-primary-400 border-l-2 border-primary-600 dark:border-primary-400 -ml-px font-medium'
                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                {item.text}
              </button>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  )
}
