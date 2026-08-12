/**
 * @orbit/shared — shared types and constants for Orbit Browser.
 *
 * Kept dependency-free on purpose: consumed by web-app, shells, and infra
 * tooling alike. Nothing sensitive lives here — this package is public.
 */

/** Shell readiness states reported by the web-app shell UI. */
export const SHELL_STATUS = {
  BOOTING: 'booting',
  READY: 'ready',
  OFFLINE: 'offline',
  ERROR: 'error',
} as const;

export type OrbitShellStatus = (typeof SHELL_STATUS)[keyof typeof SHELL_STATUS];

/** Identity ladder — one identity, one door. */
export const IDENTITY_LADDER = {
  EXPLORER: 'explorer',
  PARTICIPANT: 'participant',
  CONTRIBUTOR: 'contributor',
  CORE: 'core',
} as const;

export type IdentityLevel = (typeof IDENTITY_LADDER)[keyof typeof IDENTITY_LADDER];

/** Preload order per fleet consensus: Orbit loop → registry identity → Universe assets. */
export const PRELOAD_PHASES = ['orbit-loop', 'registry-identity', 'universe-assets'] as const;
export type PreloadPhase = (typeof PRELOAD_PHASES)[number];

/** Scope boundary — what Orbit Browser owns vs. what is explicitly out of scope. */
export const SCOPE = {
  OWN: ['rules-ui', 'ai-assist', 'preloads', 'identity'] as const,
  OUT_OF_SCOPE: ['browser-engine', 'network-stack', 'rendering-core'] as const,
} as const;
