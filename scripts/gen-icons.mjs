// Generate solid-color PWA icons (pure Node stdlib, no deps).
// Usage: node scripts/gen-icons.mjs
import { deflateSync } from 'node:zlib';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, '..', 'web-app', 'public');
mkdirSync(outDir, { recursive: true });

// BAWES design tokens: Zendesk blue #1f73b7, coral #eb6651
const bg = [0x1f, 0x73, 0xb7, 0xff];

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])));
  return Buffer.concat([len, typeBuf, data, crc]);
}

function png(size) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  // scanlines: filter byte 0 + RGBA row
  const raw = Buffer.alloc(size * (1 + size * 4));
  for (let y = 0; y < size; y++) {
    const rowStart = y * (1 + size * 4);
    raw[rowStart] = 0;
    for (let x = 0; x < size; x++) {
      const off = rowStart + 1 + x * 4;
      // simple orbit ring: coral dot center, blue ring
      const dx = x - size / 2;
      const dy = y - size / 2;
      const d = Math.sqrt(dx * dx + dy * dy);
      if (d < size * 0.08) {
        raw[off] = 0xeb; raw[off + 1] = 0x66; raw[off + 2] = 0x51; raw[off + 3] = 0xff;
      } else {
        raw[off] = bg[0]; raw[off + 1] = bg[1]; raw[off + 2] = bg[2]; raw[off + 3] = bg[3];
      }
    }
  }
  const idat = deflateSync(raw);
  return Buffer.concat([
    sig,
    chunk('IHDR', ihdr),
    chunk('IDAT', idat),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

for (const size of [192, 512]) {
  writeFileSync(join(outDir, `pwa-${size}x${size}.png`), png(size));
}
writeFileSync(join(outDir, 'apple-touch-icon.png'), png(180));
console.log('icons written to', outDir);
