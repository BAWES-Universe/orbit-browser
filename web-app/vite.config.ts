import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

// Orbit Browser — Vite config
// App-shell precache of the universe via service worker (Workbox under the hood).

// Universe entry link — the "one door". Honours a bare `UNIVERSE_URL` env var
// (or Vite's `VITE_UNIVERSE_URL`) and falls back to the BAWES playground.
const DEFAULT_UNIVERSE_URL = 'https://play.bawes';

export default defineConfig(({ mode }) => {
  // Empty prefix so non-VITE_ vars (e.g. `UNIVERSE_URL`) are picked up too.
  const env = loadEnv(mode, process.cwd(), '');
  const universeUrl = env.UNIVERSE_URL || env.VITE_UNIVERSE_URL || DEFAULT_UNIVERSE_URL;

  return {
    plugins: [
      react(),
      VitePWA({
        registerType: 'autoUpdate',
        includeAssets: ['favicon.svg', 'apple-touch-icon.png'],
        manifest: false, // served from public/manifest.webmanifest
        devOptions: { enabled: true }, // register SW in dev so E2E can validate it
        workbox: {
          // Pre-cache the app shell; runtime-cache same-origin navigations.
          globPatterns: ['**/*.{js,css,html,ico,png,svg,webmanifest}'],
          navigateFallback: '/index.html',
          runtimeCaching: [
            {
              // Universe assets — cache-first for instant repeat loads
              urlPattern: ({ url }) => url.pathname.startsWith('/universe/'),
              handler: 'CacheFirst',
              options: { cacheName: 'orbit-universe', expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 30 } },
            },
            {
              urlPattern: /^https:\/\/api\.bawes\.universe\/.*/i,
              handler: 'NetworkFirst',
              options: {
                cacheName: 'orbit-api',
                networkTimeoutSeconds: 5,
                expiration: {
                  maxEntries: 100,
                  maxAgeSeconds: 60 * 60 * 24 * 7,
                },
                cacheableResponse: {
                  statuses: [0, 200],
                },
              },
            },
          ],
        },
      }),
    ],
    define: {
      // Injected into src/identity/deviceIdentity.ts (UNIVERSE_URL constant).
      __UNIVERSE_URL__: JSON.stringify(universeUrl),
    },
    build: { outDir: 'dist', sourcemap: true },
  };
});
