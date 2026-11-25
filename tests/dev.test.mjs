import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, writeFile, readFile, readdir, rm, access } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { ensureRenderer, findLove, targetFor } from '../scripts/dev.mjs';

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
