import { registerSW } from 'virtual:pwa-register'

// Orbit Browser — app-shell precache (service worker via vite-plugin-pwa)
// Preloads the universe shell so it loads instantly on repeat visits.
registerSW({
  immediate: true,
  onOfflineReady() {
    console.log('[orbit] universe shell precached — offline-ready')
  },
})
