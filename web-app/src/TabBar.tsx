import { tabTitle, type Tab } from './tabs'
import type { MouseEvent } from 'react'

interface TabBarProps {
  tabs: Tab[]
  activeTabId: string
  onSelect: (id: string) => void
  onClose: (id: string) => void
  onNew: () => void
}

// Orbit Browser — tab strip: open, switch, and close tabs.
// The close control lives inside the tab button (VS Code style); its click
// must not also select the tab, hence stopPropagation.
export default function TabBar({ tabs, activeTabId, onSelect, onClose, onNew }: TabBarProps) {
  const handleClose = (e: MouseEvent, id: string) => {
    e.stopPropagation()
    onClose(id)
  }

  return (
    <div className="orbit-tabbar">
      <div className="tab-strip" role="tablist" aria-label="Open tabs">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            type="button"
            role="tab"
            aria-selected={tab.id === activeTabId}
            className={tab.id === activeTabId ? 'tab active' : 'tab'}
            title={tab.url || 'New Tab'}
            onClick={() => onSelect(tab.id)}
          >
            <span className="tab-title">{tabTitle(tab)}</span>
            <span
              className="tab-close"
              role="button"
              aria-label="Close tab"
              onClick={(e) => handleClose(e, tab.id)}
            >
              ✕
            </span>
          </button>
        ))}
      </div>
      <button type="button" className="tab-new" aria-label="New tab" title="New tab" onClick={onNew}>
        +
      </button>
    </div>
  )
}
