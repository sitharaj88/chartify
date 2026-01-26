import { useState } from 'react'
import { Highlight, type PrismTheme } from 'prism-react-renderer'
import { Check, Copy } from 'lucide-react'

// Custom theme based on One Dark Pro / VS Code Dark+
const customTheme: PrismTheme = {
  plain: {
    color: '#e2e8f0',
    backgroundColor: '#0f172a',
  },
  styles: [
    {
      types: ['comment', 'prolog', 'doctype', 'cdata'],
      style: { color: '#6b7280', fontStyle: 'italic' },
    },
    {
      types: ['punctuation'],
      style: { color: '#94a3b8' },
    },
    {
      types: ['property', 'tag', 'boolean', 'number', 'constant', 'symbol', 'deleted'],
      style: { color: '#f59e0b' },
    },
    {
      types: ['selector', 'attr-name', 'string', 'char', 'builtin', 'inserted'],
      style: { color: '#34d399' },
    },
    {
      types: ['operator', 'entity', 'url'],
      style: { color: '#67e8f9' },
    },
    {
      types: ['atrule', 'attr-value', 'keyword'],
      style: { color: '#c084fc' },
    },
    {
      types: ['function', 'class-name'],
      style: { color: '#60a5fa' },
    },
    {
      types: ['regex', 'important', 'variable'],
      style: { color: '#fb923c' },
    },
    {
      types: ['metadata'],
      style: { color: '#fbbf24' },
    },
  ],
}

interface CodeBlockProps {
  code: string
  language: string
  filename?: string
  showLineNumbers?: boolean
}

export function CodeBlock({ code, language, filename, showLineNumbers = true }: CodeBlockProps) {
  const [copied, setCopied] = useState(false)

  const copyToClipboard = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  // Map dart to javascript for basic highlighting if Dart is not supported
  // prism-react-renderer has limited language support
  const mappedLanguage = language === 'dart' ? 'typescript' : language

  return (
    <div className="code-block group my-4 rounded-xl overflow-hidden">
      {filename && (
        <div className="flex items-center justify-between px-4 py-2.5 bg-slate-800/80 border-b border-slate-700/50">
          <div className="flex items-center gap-3">
            <div className="flex gap-1.5">
              <div className="w-3 h-3 rounded-full bg-red-500/80" />
              <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
              <div className="w-3 h-3 rounded-full bg-green-500/80" />
            </div>
            <span className="text-sm text-slate-300 font-mono">{filename}</span>
          </div>
          <span className="text-xs text-slate-500 uppercase font-medium tracking-wider">{language}</span>
        </div>
      )}
      <div className="relative">
        <Highlight theme={customTheme} code={code.trim()} language={mappedLanguage}>
          {({ className, style, tokens, getLineProps, getTokenProps }) => (
            <pre
              className={className}
              style={{
                ...style,
                margin: 0,
                padding: '1.25rem',
                fontSize: '0.8125rem',
                lineHeight: '1.7',
                overflowX: 'auto',
              }}
            >
              {tokens.map((line, i) => (
                <div key={i} {...getLineProps({ line })} style={{ display: 'flex' }}>
                  {showLineNumbers && (
                    <span className="inline-block w-10 text-slate-600 text-right mr-4 select-none flex-shrink-0 text-xs leading-[1.7rem]">
                      {i + 1}
                    </span>
                  )}
                  <span className="flex-1">
                    {line.map((token, key) => (
                      <span key={key} {...getTokenProps({ token })} />
                    ))}
                  </span>
                </div>
              ))}
            </pre>
          )}
        </Highlight>
        <button
          onClick={copyToClipboard}
          className="absolute top-3 right-3 p-2 rounded-lg bg-slate-700/50 hover:bg-slate-600/50 text-slate-400 hover:text-white transition-all opacity-0 group-hover:opacity-100"
          title="Copy code"
        >
          {copied ? <Check size={16} className="text-green-400" /> : <Copy size={16} />}
        </button>
      </div>
    </div>
  )
}
