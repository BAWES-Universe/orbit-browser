// Orbit sidecar — fleet status (DEMO DATA)
//
// The real brick heartbeat is a later chunk. Until then the sidecar renders
// static demo status so the UI has something honest to render: every consumer
// treats `DEMO_FLEET` as fake, and the UI labels it as such. Do not wire real
// fleet queries into this module — replace it wholesale when heartbeat lands.

export type BrickStatus = 'online' | 'offline'

export interface Brick {
  id: string
  name: string
  role: string
  status: BrickStatus
}

/** True while the fleet list is static demo data (no real heartbeat yet). */
export const FLEET_IS_DEMO = true

export const DEMO_FLEET: readonly Brick[] = [
  { id: 'brick', name: 'brick', role: 'core builder', status: 'online' },
  { id: 'zero', name: 'zero', role: 'oracle', status: 'online' },
  { id: 'hermes-local', name: 'hermes-local', role: 'local agent', status: 'offline' },
  { id: 'zeus', name: 'zeus', role: 'watchtower', status: 'online' },
]
