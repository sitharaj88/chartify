import { Link } from 'react-router-dom'
import { Github, ExternalLink, Heart } from 'lucide-react'

const footerLinks = {
  product: [
    { label: 'Documentation', href: '/docs' },
    { label: 'Charts Gallery', href: '/charts' },
    { label: 'Examples', href: '/examples' },
    { label: 'Changelog', href: 'https://github.com/anthropics/chartify/releases', external: true },
  ],
  resources: [
    { label: 'Getting Started', href: '/docs/quick-start' },
    { label: 'API Reference', href: '/docs/data-models' },
    { label: 'Theming Guide', href: '/docs/theming' },
    { label: 'Best Practices', href: '/docs/performance' },
  ],
  community: [
    { label: 'GitHub', href: 'https://github.com/anthropics/chartify', external: true },
    { label: 'pub.dev', href: 'https://pub.dev/packages/chartify', external: true },
    { label: 'Flutter Dev', href: 'https://flutter.dev', external: true },
    { label: 'Dart Lang', href: 'https://dart.dev', external: true },
  ],
}

export function Footer() {
  const currentYear = new Date().getFullYear()

  return (
    <footer className="bg-slate-50 dark:bg-slate-900/50 border-t border-slate-200 dark:border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Main footer content */}
        <div className="py-12 grid grid-cols-2 md:grid-cols-4 gap-8">
          {/* Brand column */}
          <div className="col-span-2 md:col-span-1">
            <Link to="/" className="flex items-center gap-3 group">
              <div className="w-9 h-9 bg-gradient-to-br from-primary-500 via-primary-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-primary-500/25">
                <svg viewBox="0 0 24 24" className="w-5 h-5 text-white" fill="currentColor">
                  <path d="M3 13h2v8H3v-8zm4-6h2v14H7V7zm4-4h2v18h-2V3zm4 8h2v10h-2V11zm4-4h2v14h-2V7z" />
                </svg>
              </div>
              <span className="text-lg font-bold text-slate-900 dark:text-white">Chartify</span>
            </Link>
            <p className="mt-4 text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
              A powerful, customizable charting library for Flutter. Build beautiful, interactive charts with ease.
            </p>
            <div className="mt-6 flex items-center gap-3">
              <a
                href="https://github.com/anthropics/chartify"
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 rounded-lg text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
                aria-label="GitHub"
              >
                <Github size={20} />
              </a>
              <a
                href="https://pub.dev/packages/chartify"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-primary-600 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20 transition-colors"
              >
                <span>pub.dev</span>
                <ExternalLink size={14} />
              </a>
            </div>
          </div>

          {/* Product links */}
          <div>
            <h3 className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-4">
              Product
            </h3>
            <ul className="space-y-3">
              {footerLinks.product.map(link => (
                <li key={link.label}>
                  {link.external ? (
                    <a
                      href={link.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-sm text-slate-600 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                    >
                      {link.label}
                      <ExternalLink size={12} className="opacity-50" />
                    </a>
                  ) : (
                    <Link
                      to={link.href}
                      className="text-sm text-slate-600 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                    >
                      {link.label}
                    </Link>
                  )}
                </li>
              ))}
            </ul>
          </div>

          {/* Resources links */}
          <div>
            <h3 className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-4">
              Resources
            </h3>
            <ul className="space-y-3">
              {footerLinks.resources.map(link => (
                <li key={link.label}>
                  <Link
                    to={link.href}
                    className="text-sm text-slate-600 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Community links */}
          <div>
            <h3 className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-4">
              Community
            </h3>
            <ul className="space-y-3">
              {footerLinks.community.map(link => (
                <li key={link.label}>
                  <a
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1 text-sm text-slate-600 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                  >
                    {link.label}
                    <ExternalLink size={12} className="opacity-50" />
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="py-6 border-t border-slate-200 dark:border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-slate-500 dark:text-slate-400">
            &copy; {currentYear} Chartify. All rights reserved.
          </p>
          <p className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400">
            Made with <Heart size={14} className="text-red-500 fill-red-500" /> for the Flutter community
          </p>
        </div>
      </div>
    </footer>
  )
}
