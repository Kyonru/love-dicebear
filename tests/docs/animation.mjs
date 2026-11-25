// Validate exported SVG animation in a browser independently of the Lua sampler.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chromium } from 'playwright';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../..', import.meta.url));
const lua = process.env.LUA || (spawnSync('lua5.4', ['-v']).status === 0 ? 'lua5.4' : 'lua');
const generated = spawnSync(lua, ['-e', `local svg=require('love_dicebear').generate('cats', {seed='Milo',animation=true,animationSpeed=1}); io.write(svg)`], {cwd:root,encoding:'utf8'});
assert.equal(generated.status, 0, generated.stderr);
const browser = await chromium.launch({headless:true});
try {
  const page = await browser.newPage({viewport:{width:256,height:256},reducedMotion:'no-preference'});
  await page.setContent('<style>body{margin:0}svg{width:256px;height:256px}</style>'+generated.stdout);
  const count = await page.evaluate(() => document.getAnimations().length);
  assert(count > 0, 'exported SVG has no browser animations');
  await page.evaluate(() => { for (const animation of document.getAnimations()) { animation.pause(); animation.currentTime=0; } });
  const before = await page.screenshot();
  await page.evaluate(() => { for (const animation of document.getAnimations()) animation.currentTime=430; });
  const after = await page.screenshot();
  assert(!before.equals(after), 'browser animation did not change the avatar');
  await page.emulateMedia({reducedMotion:'reduce'});
  assert.equal(await page.evaluate(() => document.getAnimations().length),0,'reduced motion must disable exported animation');
  console.log(`PASS: ${count} browser SVG tracks, visible motion and reduced-motion preference`);
} finally { await browser.close(); }
