import { useEffect, useRef, useState, type FormEvent } from 'react'
import { DEMO_FLEET, FLEET_IS_DEMO, type Brick } from './fleet'

// Orbit sidecar — the fleet AI-assist panel, present in every tab.
//
// Three sections:
//   1. Fleet status  — brick/zero/hermes-local/zeus, online vs offline.
//      Static DEMO data for now (labeled `demo`); real heartbeat is a later
//      chunk and will replace `DEMO_FLEET`.
//   2. Quick actions — Spawn a Brick / Open Universe / View Bananas. Wired to
//      real shell behavior where it exists (navigation), otherwise a clearly
//      labeled local demo (chat log entry).
//   3. Chat          — local-only message log. No backend: messages append to
//      component state and replies are canned. Honestly labeled as a demo.

interface ChatMessage {
  id: number
  /** 'bot' = Orbit's own message, 'user' = the operator's — matches the
   *  existing .msg.bot / .msg.user styling and regression tests. */
  role: 'user' | 'bot'
  text: string
}

export interface OrbitSidecarProps {
  /** Whether the panel is expanded. */
  open: boolean
  /** Toggle expand/collapse (used by the header ✕ and the 💬 reopen button). */
  onToggle: () => void
  /** Open the Universe view — wired to the shell's existing navigation. */
  onOpenUniverse: () => void
}

/** Canned local reply — this chat has no backend, so we never fake a real AI. */
function localReply(text: string): string {
  const t = text.toLowerCase()
  if (t.includes('spawn') || t.includes('brick')) {
    return 'Spawn flow is demo-only for now — real Brick spawning lands in a later chunk.'
  }
  if (t.includes('banana')) {
    return '🍌 13 bananas on this identity (demo balance).'
  }
  return 'Got it — logged locally. This chat is a local-only demo (no backend yet).'
}

const WELCOME: ChatMessage = {
  id: 1,
  role: 'bot',
  text: "Hi — I'm your Orbit assistant. Fleet status and chat are local demos for now; real heartbeat and answers land in later chunks.",
}

function FleetStatus() {
  return (
    <section className="sidecar-section" aria-label="Fleet status">
      <div className="section-title">
        Fleet status
        {FLEET_IS_DEMO && <span className="demo-badge">demo</span>}
      </div>
      <ul className="fleet-list">
        {DEMO_FLEET.map((brick: Brick) => (
          <li key={brick.id} className="fleet-item" data-testid={`fleet-${brick.id}`}>
            <span className={`fleet-dot ${brick.status}`} aria-hidden="true" />
            <span className="fleet-name">{brick.name}</span>
            <span className="fleet-role">{brick.role}</span>
            <span className={`fleet-status ${brick.status}`}>{brick.status}</span>
          </li>
        ))}
      </ul>
      {FLEET_IS_DEMO && (
        <p className="demo-note">Demo status — real heartbeat arrives in a later chunk.</p>
      )}
    </section>
  )
}

interface QuickActionsProps {
  onSpawnBrick: () => void
  onOpenUniverse: () => void
  onViewBananas: () => void
}

function QuickActions({ onSpawnBrick, onOpenUniverse, onViewBananas }: QuickActionsProps) {
  return (
    <section className="sidecar-section" aria-label="Quick actions">
      <div className="section-title">Actions</div>
      <div className="quick-actions">
        <button className="qa-button" type="button" onClick={onSpawnBrick} aria-label="Spawn a Brick">
          🚀 Spawn a Brick
        </button>
        <button className="qa-button" type="button" onClick={onOpenUniverse} aria-label="Open Universe">
          🌌 Open Universe
        </button>
        <button className="qa-button" type="button" onClick={onViewBananas} aria-label="View Bananas">
          🍌 View Bananas
        </button>
      </div>
    </section>
  )
}

interface ChatPanelProps {
  messages: ChatMessage[]
  onSend: (text: string) => void
}

function ChatPanel({ messages, onSend }: ChatPanelProps) {
  const [draft, setDraft] = useState('')
  const logRef = useRef<HTMLDivElement>(null)

  // Keep the newest message in view as the log grows.
  useEffect(() => {
    const log = logRef.current
    if (log) log.scrollTop = log.scrollHeight
  }, [messages])

  const handleSend = (e: FormEvent) => {
    e.preventDefault()
    const text = draft.trim()
    if (!text) return
    onSend(text)
    setDraft('')
  }

  return (
    <div className="sidecar-chat-wrap">
      <div className="sidecar-chat" ref={logRef} aria-live="polite" aria-label="Chat log">
        {messages.map((msg) => (
          <div key={msg.id} className={`msg ${msg.role}`}>
            {msg.text}
          </div>
        ))}
      </div>
      <form className="sidecar-input" onSubmit={handleSend}>
        <input
          type="text"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder="Ask Orbit… (local demo)"
          aria-label="Chat message"
          autoCapitalize="none"
          autoCorrect="off"
          spellCheck={false}
        />
        <button type="submit" aria-label="Send message">
          Send
        </button>
      </form>
      <p className="sidecar-note">Local-only demo chat — no backend attached.</p>
    </div>
  )
}

export default function OrbitSidecar({ open, onToggle, onOpenUniverse }: OrbitSidecarProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([WELCOME])
  const nextId = useRef(2)

  const appendMessage = (role: ChatMessage['role'], text: string) => {
    const id = nextId.current
    nextId.current += 1
    setMessages((prev) => [...prev, { id, role, text }])
  }

  // Collapsed: a floating reopen button keeps the panel one click away.
  if (!open) {
    return (
      <button
        className="sidecar-reopen"
        type="button"
        onClick={onToggle}
        aria-expanded={false}
        aria-label="Open sidecar"
      >
        💬
      </button>
    )
  }

  return (
    <aside className="orbit-sidecar" aria-label="Orbit AI-assist panel">
      <div className="sidecar-header">
        <strong>
          Orbit <span className="demo-badge">demo</span>
        </strong>
        <button type="button" onClick={onToggle} aria-expanded={true} aria-label="Collapse sidecar">
          ✕
        </button>
      </div>
      <FleetStatus />
      <QuickActions
        onSpawnBrick={() =>
          appendMessage('bot', 'Spawn requested — demo only. Real Brick spawning lands in a later chunk.')
        }
        onOpenUniverse={onOpenUniverse}
        onViewBananas={() => appendMessage('bot', '🍌 13 bananas on this identity (demo balance).')}
      />
      <ChatPanel
        messages={messages}
        onSend={(text) => {
          appendMessage('user', text)
          appendMessage('bot', localReply(text))
        }}
      />
    </aside>
  )
}
