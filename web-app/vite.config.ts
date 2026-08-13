import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

// Orbit Browser — Vite config
// App-shell precache of the universe via service worker (Workbox under the hood).
export default defineConfig({
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
  build: { outDir: 'dist', sourcemap: true },
});
