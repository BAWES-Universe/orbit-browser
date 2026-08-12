/**
 * @orbit/shell-shared — the native-shell ↔ web-app contract.
 *
 * The macOS and iOS shells are thin WebKit/Chromium wrappers. Everything they
 * need to agree on with the web-app lives here: bridge protocol, message
 * shapes, and feature-flag surface. No native code in this package.
 */

import type { IdentityLevel, PreloadPhase } from '@orbit/shared';

/** Direction of a shell↔web message. */
export type BridgeDirection = 'shell-to-web' | 'web-to-shell';

/** Messages the native shell sends into the web-app. */
export type ShellToWebMessage =
  | { type: 'shell-ready'; version: string }
  | { type: 'identity-updated'; level: IdentityLevel; handle?: string }
  | { type: 'preload-status'; phase: PreloadPhase; ok: boolean }
  | { type: 'offline-changed'; offline: boolean };

/** Messages the web-app sends out to the native shell. */
export type WebToShellMessage =
  | { type: 'request-identity' }
  | { type: 'open-external'; url: string }
  | { type: 'set-rule'; ruleId: string; enabled: boolean };

/** Canonical version of the bridge protocol. Bump on breaking changes. */
export const BRIDGE_VERSION = '1.0.0';

/** Feature flags the web-app can query from the shell. */
export interface ShellCapabilities {
  nativePreloads: boolean;
  identityProvider: boolean;
  rulesEnforcement: boolean;
  aiAssist: boolean;
}
