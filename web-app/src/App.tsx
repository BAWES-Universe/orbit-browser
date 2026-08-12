import { useState } from 'react';
import { OrbitShellStatus, SHELL_STATUS } from '@orbit/shared';

function App() {
  const [status] = useState<OrbitShellStatus>(SHELL_STATUS.READY);

  return (
    <main style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 640, margin: '0 auto', padding: '2rem' }}>
      <h1>Orbit Browser</h1>
      <p>
        The hardened shell browser for the BAWES Universe. This is the web-app shell scaffold —
        rules-enforcement UI, AI assist, preloads, and identity land here next.
      </p>
      <p>
        Shell status: <strong>{status}</strong>
      </p>
      <p>
        <em>Zero browser internals. The door, not the product.</em>
      </p>
    </main>
  );
}

export default App;
