import { tabTitle, type Tab } from './tabs'

interface TabBarProps {
  tabs: Tab[]
  activeTabId: string
  onSelect: (id: string) => void
  onClose: (id: string) => void
  onNew: () => void
}

// Orbit Browser — tab strip: open, switch, and close tabs.
// CodeRabbit fix (Major): the close control is now a SIBLING button of the tab
// button inside a non-interactive container — both are keyboard-focusable, no
// nested interactive elements (button-in-button was a11y-invalid).
export default function TabBar({ tabs, activeTabId, onSelect, onClose, onNew }: TabBarProps) {
  return (
    <div className="orbit-tabbar">
      <div className="tab-strip" role="tablist" aria-label="Open tabs">
        {tabs.map((tab) => (
          <div
            key={tab.id}
            role="tab"
            aria-selected={tab.id === activeTabId}
            className={tab.id === activeTabId ? 'tab active' : 'tab'}
            title={tab.url || 'New Tab'}
          >
            <button
              type="button"
              className="tab-select"
              onClick={() => onSelect(tab.id)}
            >
              <span className="tab-title">{tabTitle(tab)}</span>
            </button>
            <button
              type="button"
              className="tab-close"
              aria-label={`Close tab ${tabTitle(tab)}`}
              onClick={() => onClose(tab.id)}
            >
              ✕
            </button>
          </div>
        ))}
      </div>
      <button type="button" className="tab-new" aria-label="New tab" title="New tab" onClick={onNew}>
        +
      </button>
    </div>
  )
}
