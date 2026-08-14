import { useState } from 'react'
import { formatDeviceLabel, getOrCreateDeviceIdentity, UNIVERSE_URL } from './deviceIdentity'

/**
 * Identity chip — renders the user's identity in the workspace header.
 *
 * Honest by design: this is a LOCAL device identity (UUID in localStorage),
 * not an account. The "Sign in" affordance is a placeholder that says so —
 * full auth wiring (registry identity) lands in a later chunk.
 */
export default function IdentityChip() {
  // Lazy init: reads the persisted identity or creates + persists it once.
  // Idempotent, so StrictMode double-invocation is harmless.
  const [identity] = useState(getOrCreateDeviceIdentity)
  const [authNoteOpen, setAuthNoteOpen] = useState(false)
  const shortLabel = formatDeviceLabel(identity.id)

  return (
    <div className="identity-chip" data-testid="identity-chip">
      <span className="identity-avatar" aria-hidden="true">
        {shortLabel[0]?.toUpperCase() ?? '?'}
      </span>
      <span className="identity-text">
        <span className="identity-name" data-testid="identity-name">
          device-{shortLabel}
        </span>
        <span className="identity-status">local device identity</span>
      </span>
      {/* Universe entry link — the door (preload step: one identity, one door) */}
      <a
        className="identity-universe-link"
        data-testid="universe-entry-link"
        href={UNIVERSE_URL}
        title="Open the Universe"
      >
        🌌
      </a>
      <button
        type="button"
        className="identity-signin"
        aria-expanded={authNoteOpen}
        aria-controls="identity-auth-note"
        onClick={() => setAuthNoteOpen((open) => !open)}
      >
        Sign in
      </button>
      {authNoteOpen && (
        <div
          className="identity-auth-note"
          id="identity-auth-note"
          data-testid="identity-auth-note"
          role="note"
        >
          Sign-in isn't wired yet — this is your local device identity. Full auth
          (registry identity) ships in a later chunk.
        </div>
      )}
    </div>
  )
}
