import { useState, type FormEvent } from 'react'
import './App.css'

// Orbit Browser — workspace shell (first build chunk)
// Left: universe dock · Center: universe viewport · Right: Orbit sidecar
export default function App() {
  const [sidecarOpen, setSidecarOpen] = useState(true)
  const [url, setUrl] = useState('')
  const [currentUrl, setCurrentUrl] = useState('')

  const navigate = (e: FormEvent) => {
    e.preventDefault()
    const target = url.trim() || 'browser.bawes'
    // Normalize: bare words → search? plain URLs load as-is
    setCurrentUrl(target.startsWith('http') ? target : `https://${target}`)
    setUrl('')
  }

  return (
    <div className="orbit-shell">
      {/* Universe dock — the places you can go */}
      <aside className="orbit-dock">
        <div className="dock-logo">🪐</div>
        <nav className="dock-nav">
          <button className="dock-item active" title="Universe">🌌</button>
          <button className="dock-item" title="Plugn stores">🏪</button>
          <button className="dock-item" title="Yo3an food">🍽️</button>
          <button className="dock-item" title="Planner">🥗</button>
          <button className="dock-item" title="Mail">✉️</button>
          <button className="dock-item" title="Storage">🗄️</button>
        </nav>
        <div className="dock-spacer" />
        <div className="dock-profile" title="Your bananas">🍌 13</div>
      </aside>

      {/* Browser chrome — URL bar (core browser behavior, regression-tested) */}
      <div className="orbit-chrome">
        <form className="url-bar" onSubmit={navigate} role="search" aria-label="Address bar">
          <input
            type="text"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="Enter a URL or search…"
            aria-label="URL input"
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
          />
          <button type="submit" aria-label="Go">↵</button>
        </form>
        {currentUrl && (
          <div className="current-url" data-testid="current-url">{currentUrl}</div>
        )}
      </div>

      <div className="orbit-shell-row">
      {/* Universe viewport — the world itself (pre-cached, instant) */}
      <main className="orbit-viewport">
        <div className="viewport-status">
          <span className="status-dot online" /> UniverseOS — pre-cached · offline-ready
        </div>
        <div className="viewport-placeholder">
          <h1>Welcome to the Universe</h1>
          <p>The world loads here — pre-cached, instant, native.</p>
          <p className="hint">Browser shell v0.1 — workspace UI live</p>
        </div>
      </main>

      {/* Orbit sidecar — the fleet assistant, in every tab */}
      {sidecarOpen && (
        <aside className="orbit-sidecar">
          <div className="sidecar-header">
            <strong>Orbit</strong>
            <button onClick={() => setSidecarOpen(false)} aria-label="Close sidecar">✕</button>
          </div>
          <div className="sidecar-chat">
            <div className="msg bot">Hi — I'm your Orbit assistant. Ask me anything about the universe, or tell me what to build.</div>
            <div className="msg user">Build me a storefront</div>
            <div className="msg bot">On it — spawning a Brick for your project. You pay for the time it works.</div>
          </div>
          <div className="sidecar-input">
            <input placeholder="Ask Orbit… (spawn a Brick to build)" aria-label="Ask Orbit" />
            <button>↑</button>
          </div>
        </aside>
      )}

      {/* Sidecar toggle when closed */}
      {!sidecarOpen && (
        <button className="sidecar-reopen" onClick={() => setSidecarOpen(true)}>💬</button>
      )}
      </div>
    </div>
  )
}
