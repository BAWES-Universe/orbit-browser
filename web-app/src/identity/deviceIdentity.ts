/**
 * Device identity — the local, first rung of the identity ladder.
 *
 * Identity preload order (fleet consensus): Orbit loop → registry identity →
 * universe assets. This module is the registry-identity preload step, kept
 * deliberately LOCAL-ONLY: a UUID generated once per browser profile and
 * persisted in localStorage. No backend, no credentials — full auth wiring
 * is a later chunk, and the UI says so.
 *
 * The universe entry link ("one identity, one door") is resolved here too so
 * the shell can preload it up front — see {@link UNIVERSE_URL}.
 */

/** localStorage key holding the device identity record. */
export const DEVICE_IDENTITY_STORAGE_KEY = 'orbit.device-identity'

/** Device-local identity record. */
export interface DeviceIdentity {
  /** Version 4 UUID, generated once per device (browser profile). */
  id: string
  /** ISO timestamp of first creation — surfaced when registry wiring lands. */
  createdAt: string
}

/**
 * Universe entry link — the "one door" into the BAWES Universe.
 * Configurable via the `UNIVERSE_URL` env var (or Vite's `VITE_UNIVERSE_URL`);
 * defaults to the Universe playground. Injected at dev/build time by
 * vite.config.ts (see `define`). `.env.example` documents the override.
 */
declare const __UNIVERSE_URL__: string | undefined

export const UNIVERSE_URL: string = __UNIVERSE_URL__ ?? 'https://play.bawes'

/** Render a UUID as a short, human-scale device label, e.g. "3f2c1a4e". */
export function formatDeviceLabel(id: string): string {
  return id.split('-')[0] ?? id
}

/** Generate a fresh RFC-4122 v4 UUID (crypto.randomUUID when available). */
export function createUuid(): string {
  const c = globalThis.crypto
  if (c?.randomUUID) return c.randomUUID()
  if (c?.getRandomValues) {
    // Hand-rolled v4 for browsers without randomUUID (non-secure contexts).
    const bytes = c.getRandomValues(new Uint8Array(16))
    bytes[6] = (bytes[6]! & 0x0f) | 0x40
    bytes[8] = (bytes[8]! & 0x3f) | 0x80
    const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('')
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
  }
  // Last-resort fallback (no Web Crypto at all): still unique per call.
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (ch) => {
    const r = (Math.random() * 16) | 0
    const v = ch === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

export function createDeviceIdentity(): DeviceIdentity {
  return { id: createUuid(), createdAt: new Date().toISOString() }
}

/** Read the persisted device identity, or null when absent or corrupt. */
export function loadDeviceIdentity(): DeviceIdentity | null {
  try {
    const raw = localStorage.getItem(DEVICE_IDENTITY_STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<DeviceIdentity> | null
    if (parsed && typeof parsed.id === 'string' && parsed.id.length > 0) {
      return {
        id: parsed.id,
        createdAt: typeof parsed.createdAt === 'string' ? parsed.createdAt : new Date().toISOString(),
      }
    }
    return null
  } catch {
    // Corrupt/unreadable storage — treat as absent; a fresh identity is created.
    return null
  }
}

/**
 * Identity preload: return the persisted device identity, creating and
 * persisting one on first run. Idempotent — safe to call on every mount.
 */
export function getOrCreateDeviceIdentity(): DeviceIdentity {
  const existing = loadDeviceIdentity()
  if (existing) return existing
  const created = createDeviceIdentity()
  try {
    localStorage.setItem(DEVICE_IDENTITY_STORAGE_KEY, JSON.stringify(created))
  } catch {
    // Storage unavailable (private mode, quota) — identity lives for this session only.
  }
  return created
}

const UNIVERSE_PRECONNECT_ID = 'orbit-universe-preconnect'

/**
 * Universe-assets preload: open a preconnect to the entry link's origin so
 * the first trip through the door is instant. No-op when document is missing
 * (SSR/typecheck) or when UNIVERSE_URL is not a valid URL.
 */
export function preconnectToUniverse(universeUrl: string = UNIVERSE_URL): void {
  if (typeof document === 'undefined') return
  if (document.getElementById(UNIVERSE_PRECONNECT_ID)) return
  try {
    const origin = new URL(universeUrl).origin
    const link = document.createElement('link')
    link.id = UNIVERSE_PRECONNECT_ID
    link.rel = 'preconnect'
    link.href = origin
    document.head.appendChild(link)
  } catch {
    // Invalid UNIVERSE_URL — skip preconnect; the entry link still renders.
  }
}
