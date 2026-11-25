// Node is a development dependency only. Every SVG under test is generated in Lua.
import { Avatar, Style } from '@dicebear/core';
import { readFileSync, writeFileSync, mkdtempSync, rmSync, readdirSync } from 'node:fs';
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
import casesForStyle from './style_cases.mjs';
import botttsCases from './bottts_cases.mjs';
const names = process.argv.slice(2);
const available = readdirSync('vendor').filter(n => n.endsWith('.json')).map(n => n.slice(0,-5)).sort();
for (const name of names) assert(available.includes(name), `Unknown style: ${name}`);
let total = 0;
// The pinned catalog uses schema 2 animation annotations. This library produces
// static SVGs; Core 10.7.0 validates schema 1, so compare the static projection.
// Keep the complete, unmodified definition in vendor/ and the Lua style module.
function staticDefinition(value) {
  if (Array.isArray(value)) return value.map(staticDefinition);
  if (value && typeof value === 'object') return Object.fromEntries(
    Object.entries(value).filter(([key]) => key !== 'animations').map(([key,v]) => [key,staticDefinition(v)]));
  return value;
}
function lua(value) {
  if (typeof value === 'string') return JSON.stringify(value);
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  if (Array.isArray(value)) return `{${value.map(lua).join(',')}}`;
  return `{${Object.entries(value).map(([k,v]) => `[${lua(k)}]=${lua(v)}`).join(',')}}`;
}
for (const name of names.length ? names : available) {
const definition = JSON.parse(readFileSync(`vendor/${name}.json`, 'utf8'));
const style = new Style(staticDefinition(definition));
const options = name === 'bottts' ? botttsCases(definition) : casesForStyle(definition);
const cases = options.map(options => ({style:name, options}));
const directory = mkdtempSync(join(tmpdir(), 'love-dicebear-parity-'));
try {
  writeFileSync(join(directory,'cases.lua'), `return ${lua(cases)}\n`);
  const vectors = options.slice(0,9).flatMap(({seed}) => ['eyesVariant','baseColor',''].map(key =>
    ({seed, key, hash:Fnv1a.hash(seed), value:new Prng(seed).getValue(key)})));
  writeFileSync(join(directory,'prng.lua'), `return ${lua(vectors)}\n`);
  const command = process.env.LOVE || process.env.LUA || 'lua';
  const args = process.env.LOVE ? ['.','--parity',directory] : ['tests/parity.lua',directory];
  const run = spawnSync(command, args, {encoding:'utf8', timeout:60000});
  assert.equal(run.status, 0, run.error?.message || run.stderr || run.stdout);
  for (let i = 0; i < cases.length; i++) {
    assert.equal(readFileSync(join(directory,`${i+1}.svg`),'utf8'), new Avatar(style,options[i]).toString(),
      `SVG differs for ${name} case ${i+1}: ${JSON.stringify(options[i])}`);
  }
  console.log(`PASS ${name}: ${cases.length} byte-identical SVGs and round-trips`);
  total += cases.length;
} finally {
  rmSync(directory,{recursive:true,force:true});
}
}
console.log(`PASS: ${total} SVGs match DiceBear Core 10.7.0`);
