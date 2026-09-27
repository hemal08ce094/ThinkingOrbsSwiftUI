// Regenerates Tests/ThinkingOrbsTests/golden.json from the published
// thinking-orbs engine (npm), mirroring upstream scripts/extract-golden.ts.
// Point it at a built copy of the engine: the npm package, or this repo's
// web/ folder after `cd web && npm ci && npm run build`:
//   node scripts/extract-golden.mjs web
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const pkgDir = resolve(process.argv[2] ?? `${process.env.HOME}/node_modules/thinking-orbs`);
const pkg = JSON.parse(readFileSync(resolve(pkgDir, 'package.json'), 'utf8'));
const { MODE_FRAMES, resolvePreset, STATE_TO_MODE } = await import(pathToFileURL(resolve(pkgDir, 'dist/engine.es.js')).href);

const STATES = Object.keys(STATE_TO_MODE);
const SIZES = [64, 20];
const TIMES = [0.6, 1.7, 3.3, 5.1];
const r6 = (n) => Number(n.toFixed(6));

const cases = [];
for (const state of STATES)
  for (const size of SIZES) {
    const { mode, opts } = resolvePreset(state, size);
    for (const t of TIMES) {
      const f = MODE_FRAMES[mode](size, t, opts);
      cases.push({
        key: `${state}-${size}-${t}`, state, size, mode, t,
        dots: f.dots.flatMap((d) => [d.x, d.y, d.z, d.r, d.white, d.a ?? 1].map(r6)),
        lines: f.lines.flatMap((l) => [l.x1, l.y1, l.x2, l.y2, l.white, l.a ?? 1, l.w].map(r6))
      });
    }
  }
const resolved = Object.fromEntries(STATES.flatMap((s) => SIZES.map((z) => [`${s}-${z}`, resolvePreset(s, z)])));
const here = dirname(fileURLToPath(import.meta.url));
writeFileSync(
  resolve(here, '../Tests/ThinkingOrbsTests/golden.json'),
  JSON.stringify({ sourceLibrary: { name: pkg.name, version: pkg.version }, tolerance: 1e-4, times: TIMES, resolved, cases }) + '\n'
);
console.log(`golden.json — thinking-orbs ${pkg.version}, ${cases.length} cases`);
