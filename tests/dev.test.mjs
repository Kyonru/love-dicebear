import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, writeFile, readFile, readdir, realpath, rm, access, copyFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { ensureRenderer, findLove, targetFor, rendererFor } from '../scripts/dev.mjs';

async function temporary(t) {
  const root = await mkdtemp(join(tmpdir(), 'love-dicebear-dev-test-'));
  t.after(() => rm(root, {recursive:true, force:true}));
  return root;
}

test('selects supported native packages and rejects unsupported platforms', () => {
  assert.equal(targetFor('darwin','arm64').name, 'macos-arm64');
  assert.equal(targetFor('darwin','x64').name, 'macos-x64');
  assert.equal(targetFor('linux','x64').binary, 'liblove_thorvg.so');
  assert.equal(targetFor('win32','x64').binary, 'love_thorvg.dll');
  assert.throws(() => targetFor('linux','arm64'), /No prebuilt/);
});

test('selects HTTP without requiring a ThorVG setup and validates renderer arguments', () => {
  assert.equal(rendererFor([]),'thorvg');
  assert.equal(rendererFor(['--style','initials','--renderer','http']),'http');
  assert.equal(rendererFor(['--http-test']),'http');
  assert.throws(() => rendererFor(['--renderer']), /must be/);
  assert.throws(() => rendererFor(['--renderer','unknown']), /must be/);
});

test('HTTP launcher forwards game arguments without installing ThorVG', {skip:process.platform === 'win32'}, async t => {
  const root = await temporary(t);
  await mkdir(join(root,'scripts'));
  await copyFile(new URL('../scripts/dev.mjs',import.meta.url),join(root,'scripts/dev.mjs'));
  const executable = join(root,'fake-love');
  const capture = join(root,'arguments.json');
  await writeFile(executable, '#!/usr/bin/env node\nrequire("node:fs").writeFileSync(process.env.LOVE_TEST_CAPTURE,JSON.stringify(process.argv.slice(2)));\n', {mode:0o755});
  const run = spawnSync(process.execPath,[join(root,'scripts/dev.mjs'),'--renderer','http','--style','initials'], {
    encoding:'utf8',timeout:5000,env:{...process.env,LOVE:executable,LOVE_TEST_CAPTURE:capture},
  });
  assert.equal(run.status,0,run.stderr || run.error?.message);
  assert.deepEqual(JSON.parse(await readFile(capture,'utf8')),[await realpath(root),'--renderer','http','--style','initials']);
  await assert.rejects(access(join(root,'love_thorvg')));
});

test('reuses an existing renderer without reading or downloading an archive', async t => {
  const root = await temporary(t);
  const target = targetFor();
  const native = join(root,'love_thorvg','native',target.name);
  await mkdir(native,{recursive:true});
  await writeFile(join(root,'love_thorvg','init.lua'),'-- local development version');
  await writeFile(join(native,target.binary),'fixture');
  await ensureRenderer(root,{archive:join(root,'missing.zip')});
  assert.equal(await readFile(join(root,'love_thorvg','init.lua'),'utf8'),'-- local development version');
});

test('leaves incomplete manual installations untouched', async t => {
  const root = await temporary(t);
  await mkdir(join(root,'love_thorvg'));
  await writeFile(join(root,'love_thorvg','custom.txt'),'keep');
  await assert.rejects(ensureRenderer(root), /incomplete/);
  assert.equal(await readFile(join(root,'love_thorvg','custom.txt'),'utf8'),'keep');
});

test('rejects corrupt downloads and cleans staging files', async t => {
  const root = await temporary(t);
  const archive = join(root,'invalid.zip');
  await writeFile(archive,'not the pinned release');
  await assert.rejects(ensureRenderer(root,{archive}), /checksum mismatch/);
  await assert.rejects(access(join(root,'love_thorvg')));
  assert.deepEqual(await readdir(join(root,'.dev')),[]);
});

test('honors explicit LOVE paths, including spaces, and reports missing executables', async t => {
  const root = await temporary(t);
  const executable = join(root,'my love');
  await writeFile(executable,'fixture',{mode:0o755});
  assert.equal(await findLove({LOVE:executable}),executable);
  await assert.rejects(findLove({LOVE:join(root,'missing')}), /LÖVE was not found/);
});

test('installs the real pinned release with its license notices', {
  skip: !process.env.TEST_THORVG_ARCHIVE,
}, async t => {
  const root = await temporary(t);
  await ensureRenderer(root,{archive:process.env.TEST_THORVG_ARCHIVE});
  for (const file of ['init.lua','LICENSE','THORVG-LICENSE','README.md','.love-dicebear-release']) {
    await access(join(root,'love_thorvg',file));
  }
  assert.deepEqual(await readdir(join(root,'.dev')),[]);
});
