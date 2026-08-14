/// <reference types="vite/client" />
/// <reference types="vite-plugin-pwa/client" />

interface ImportMetaEnv {
  /** Optional override for the universe entry link (see UNIVERSE_URL). */
  readonly VITE_UNIVERSE_URL?: string
}
