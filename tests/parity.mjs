// Node is a development dependency only. Every SVG under test is generated in Lua.
import { Avatar, Style } from '@dicebear/core';
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

const require = createRequire(import.meta.url);
const coreDirectory = new URL('.', pathToFileURL(require.resolve('@dicebear/core')));
const { Prng } = await import(new URL('Prng.js', coreDirectory));
const { Fnv1a } = await import(new URL('Prng/Fnv1a.js', coreDirectory));
const definition = JSON.parse(readFileSync('vendor/bottts.json', 'utf8'));
const style = new Style(definition);
const cases = ['', 'alice', 'Bob', 'Ada 🤖', '日本語', 'é', 'e\u0301', '𐀀', '􏿿'].map(seed => ({seed}));
for (const [name, component] of Object.entries(definition.components)) {
  for (const variant of Object.keys(component.variants)) {
    cases.push({seed: 'every-variant', [`${name}Variant`]: variant, textureProbability: 100});
  }
}
cases.push(
  {seed:'editor', size:256, title:'<Robot & "friend">', eyesVariant:'happy', baseColor:'abc', backgroundColor:'1234'},
  {seed:'transform', flip:'both', rotate:32.12345, scale:0.75, translateX:12.5, translateY:-8, borderRadius:25, backgroundColor:'ffffff'},
  {seed:'ranges', rotate:[-19,21], scale:[0.3,1.5], translateX:[20,-20], borderRadius:[8,20]},
  {seed:'single', scale:[0.8], rotate:[], eyesVariant:['happy','happy','dizzy'], baseColor:['abc','aabbcc','000000']},
  {seed:'weights', eyesVariant:{happy:3,dizzy:0,hearts:9}, mouthVariant:{bite:0,diagram:0}},
  {seed:'hidden', eyesProbability:0, headProbability:0, sidesProbability:0, topProbability:0, mouthProbability:0},
  {seed:'empty', eyesVariant:[], textureVariant:[], baseColor:[], backgroundColor:[]},
  {seed:'avoid', baseColor:['ffffff','000000'], backgroundColor:'ffffff'},
  {seed:'fallback', baseColor:['ffffff'], backgroundColor:'ffffff'},
  {seed:'alpha', baseColor:['abcdef00','123456ff'], backgroundColor:'abcdef80'},
);
for (let i = 0; i < 80; i++) cases.push({seed:`generated-${i}`, textureProbability:i % 101, eyesProbability:33.5});

function lua(value) {
  if (typeof value === 'string') return JSON.stringify(value);
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  if (Array.isArray(value)) return `{${value.map(lua).join(',')}}`;
  return `{${Object.entries(value).map(([k,v]) => `[${lua(k)}]=${lua(v)}`).join(',')}}`;
}
const directory = mkdtempSync(join(tmpdir(), 'love-dicebear-parity-'));
try {
  writeFileSync(join(directory,'cases.lua'), `return ${lua(cases)}\n`);
  const vectors = cases.slice(0,9).flatMap(({seed}) => ['eyesVariant','baseColor',''].map(key =>
    ({seed, key, hash:Fnv1a.hash(seed), value:new Prng(seed).getValue(key)})));
  writeFileSync(join(directory,'prng.lua'), `return ${lua(vectors)}\n`);
  const command = process.env.LOVE || process.env.LUA || 'lua';
  const args = process.env.LOVE ? ['.','--parity',directory] : ['tests/parity.lua',directory];
  const run = spawnSync(command, args, {encoding:'utf8', timeout:60000});
  assert.equal(run.status, 0, run.error?.message || run.stderr || run.stdout);
  for (let i = 0; i < cases.length; i++) {
    assert.equal(readFileSync(join(directory,`${i+1}.svg`),'utf8'), new Avatar(style,cases[i]).toString(),
      `SVG differs from DiceBear Core 10.7.0 for case ${i+1}: ${JSON.stringify(cases[i])}`);
  }
  console.log(`PASS: ${cases.length} byte-identical SVGs and ${vectors.length} PRNG vectors`);
} finally {
  rmSync(directory,{recursive:true,force:true});
}
