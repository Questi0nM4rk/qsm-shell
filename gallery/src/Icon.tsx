import type { ReactNode } from 'react'

export type IconName =
  | 'apps'
  | 'battery'
  | 'bell'
  | 'files'
  | 'network'
  | 'pin'
  | 'power'
  | 'terminal'
  | 'theme'
  | 'volume'

export function Icon({ name }: { name: IconName }) {
  const glyphs: Record<IconName, ReactNode> = {
    apps: <><rect x="4" y="4" width="6" height="6" rx="1" /><rect x="14" y="4" width="6" height="6" rx="1" /><rect x="4" y="14" width="6" height="6" rx="1" /><rect x="14" y="14" width="6" height="6" rx="1" /></>,
    battery: <><rect x="4" y="7" width="15" height="10" rx="2" /><path d="M19 10h2v4h-2M7 10h7v4H7z" /></>,
    bell: <><path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 2 6H4c.5-.5 2-2 2-6zM10 19a2 2 0 0 0 4 0" /></>,
    files: <><path d="M4 6h6l2 2h8v11H4z" /><path d="M4 6V4h6l2 2" /></>,
    network: <><path d="M4 10a11 11 0 0 1 16 0M7 13a7 7 0 0 1 10 0M10 16a3 3 0 0 1 4 0M12 19h.01" /></>,
    pin: <><path d="m8 4 8 8M9 9l-4 4 6 6 4-4-6-6M4 20l5-5" /></>,
    power: <><path d="M12 3v8M7 6.5a8 8 0 1 0 10 0" /></>,
    terminal: <><path d="m5 7 4 4-4 4M12 16h7" /></>,
    theme: <><path d="M12 3a9 9 0 1 0 9 9c0-2-2-2-3-2s-2 1-3 0 0-3-3-3 0-2 0-4zM8 9h.01M11 6h.01M6 13h.01" /></>,
    volume: <><path d="M4 9v6h4l5 4V5L8 9H4z" /><path d="M16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11" /></>,
  }

  return <svg className="icon" viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">{glyphs[name]}</svg>
}