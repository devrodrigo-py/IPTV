/**
 * Renders every raster brand asset from the single SVG source
 * (src/components/brand/markSvg.ts): favicon, Android launcher icons,
 * Android TV banner and splash screens.
 *
 *   npx vite-node scripts/generate-brand.ts
 *
 * Uses the Playwright Chromium that renders the web app, so the wordmark is
 * set in the bundled Outfit font exactly as in the UI.
 */
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { markSvg } from '../src/components/brand/markSvg';

// Playwright is used from the machine's install (not a project dependency).
const { chromium } = createRequire(import.meta.url)('playwright');

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const res = join(root, 'android/app/src/main/res');
const fontPath = join(root, 'node_modules/@fontsource/outfit/files/outfit-latin-700-normal.woff2');
const fontData = readFileSync(fontPath).toString('base64');

const BG = '#060608';

function page(body: string, w: number, h: number, transparent = false) {
  return `<!doctype html><html><head><style>
@font-face{font-family:Outfit;font-weight:700;src:url(data:font/woff2;base64,${fontData}) format('woff2');}
html,body{margin:0;width:${w}px;height:${h}px;overflow:hidden;background:${transparent ? 'transparent' : BG};}
.c{width:100%;height:100%;display:flex;align-items:center;justify-content:center;position:relative;}
.glow{position:absolute;inset:0;background:radial-gradient(60% 70% at 50% 45%, rgba(124,92,255,0.28), rgba(255,77,141,0.08) 45%, transparent 70%);}
.word{font-family:Outfit;font-weight:700;color:#fff;letter-spacing:-0.02em;line-height:1;margin-top:-0.08em;}
</style></head><body>${body}</body></html>`;
}

const lockup = (mark: number, gap: number) =>
  `<div style="display:flex;align-items:center;gap:${gap}px;position:relative">${markSvg('m', mark)}<span class="word" style="font-size:${Math.round(mark * 0.78)}px">nebula</span></div>`;

async function main() {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ deviceScaleFactor: 1 });
  const p = await ctx.newPage();

  async function render(out: string, w: number, h: number, body: string, transparent = false) {
    await p.setViewportSize({ width: w, height: h });
    await p.setContent(page(body, w, h, transparent));
    await p.evaluate(() => document.fonts.ready);
    mkdirSync(dirname(out), { recursive: true });
    await p.screenshot({ path: out, omitBackground: transparent });
    console.log('wrote', out.replace(root + '/', ''), `${w}x${h}`);
  }

  // Favicon (vector + PNG fallback)
  writeFileSync(join(root, 'public/favicon.svg'), markSvg('f', 64));
  await render(join(root, 'public/favicon.png'), 128, 128, `<div class="c">${markSvg('f', 112)}</div>`, true);

  // Launcher icons: legacy square/round + adaptive foreground (108dp with a 66dp safe zone)
  const densities: Record<string, number> = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
  for (const [d, k] of Object.entries(densities)) {
    const icon = Math.round(48 * k);
    const fg = Math.round(108 * k);
    const iconBody = `<div class="c" style="border-radius:${Math.round(icon * 0.22)}px;background:${BG};overflow:hidden"><div class="glow"></div>${markSvg('i', Math.round(icon * 0.68))}</div>`;
    await render(join(res, `mipmap-${d}/ic_launcher.png`), icon, icon, iconBody, true);
    const roundBody = `<div class="c" style="border-radius:50%;background:${BG};overflow:hidden"><div class="glow"></div>${markSvg('r', Math.round(icon * 0.6))}</div>`;
    await render(join(res, `mipmap-${d}/ic_launcher_round.png`), icon, icon, roundBody, true);
    await render(join(res, `mipmap-${d}/ic_launcher_foreground.png`), fg, fg, `<div class="c">${markSvg('a', Math.round(fg * 0.5))}</div>`, true);
  }

  // Mark used inside the native player (top bar)
  await render(join(res, 'drawable-xhdpi/nebula_mark.png'), 96, 96, `<div class="c">${markSvg('p', 96)}</div>`, true);

  // Android TV home-screen banner (320x180 at xhdpi)
  const banner = `<div class="c"><div class="glow"></div>${lockup(64, 18)}</div>`;
  await render(join(res, 'drawable-xhdpi/banner.png'), 320, 180, banner);
  await render(join(res, 'drawable/banner.png'), 320, 180, banner);

  // Splash screens: every drawable-*/splash.png Capacitor generated, same size
  const dirs = readdirSync(res).filter((d) => d.startsWith('drawable') && existsSync(join(res, d, 'splash.png')));
  for (const d of dirs) {
    const file = join(res, d, 'splash.png');
    const dims = await p.evaluate(async (b64) => {
      const img = new Image();
      img.src = 'data:image/png;base64,' + b64;
      await img.decode();
      return [img.naturalWidth, img.naturalHeight];
    }, readFileSync(file).toString('base64'));
    const [w, h] = dims as [number, number];
    const mark = Math.round(Math.min(w, h) * 0.16);
    await render(file, w, h, `<div class="c"><div class="glow"></div>${lockup(mark, Math.round(mark * 0.3))}</div>`);
  }

  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
