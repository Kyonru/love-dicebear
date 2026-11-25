import { createHash } from 'node:crypto';
import { access, copyFile, lstat, mkdir, mkdtemp, readFile, realpath, rename, rm, writeFile } from 'node:fs/promises';
import { constants } from 'node:fs';
import { dirname, delimiter, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const version = 'v0.2.0';
const targets = {
  'darwin-arm64': ['macos-arm64', 'liblove_thorvg.dylib', '7c489673a3433053a6af2037019a6b33689339fd804c91095302669058382623'],
  'darwin-x64': ['macos-x64', 'liblove_thorvg.dylib', 'd13337a6cd783cd29dd7455f733a085821f4624fdbf4b51a79f9438de06d48e4'],
  'linux-x64': ['linux-x64', 'liblove_thorvg.so', 'cb960e168921f8024b666279a768034638cdd474ade1170dcdcef9245bd9d77c'],
  'win32-x64': ['windows-x64', 'love_thorvg.dll', '3e2588e014ed7f8f59d6b2e28ea30e45939fa2ff96d0eaa84c8cf6879ca8b3a6'],
};

export function targetFor(platform = process.platform, arch = process.arch) {
  const target = targets[`${platform}-${arch}`];
  if (!target) throw new Error(`No prebuilt love-thorvg package for ${platform}/${arch}. Install love_thorvg/ manually.`);
  const [name, binary, sha256] = target;
  return {name, binary, sha256};
}

async function exists(path) {
  try { await lstat(path); return true; }
  catch (error) { if (error.code === 'ENOENT') return false; throw error; }
}

async function validateRenderer(directory, target) {
  for (const relative of ['init.lua', `native/${target.name}/${target.binary}`]) {
    await access(join(directory, relative));
  }
}

export async function ensureRenderer(root, {archive = process.env.LOVE_THORVG_ARCHIVE} = {}) {
  const target = targetFor();
  const destination = join(root, 'love_thorvg');
  if (await exists(destination)) {
    try { await validateRenderer(destination, target); }
    catch { throw new Error(`Existing ${destination} is incomplete for ${target.name}. Move it aside to allow installation; it has not been changed.`); }
    console.log(`Using existing love_thorvg/ (${target.name}).`);
    return;
  }

  // Stage on the same filesystem so only a complete install becomes visible.
  const cache = join(root, '.dev');
  await mkdir(cache, {recursive:true});
  const staging = await mkdtemp(join(cache, 'thorvg-'));
  const name = `love-thorvg-${version}-${target.name}`;
  const url = `https://github.com/Kyonru/love-thorvg/releases/download/${version}/${name}.zip`;
  try {
    let bytes;
    if (archive) {
      console.log(`Reading ${archive}`);
      bytes = await readFile(archive);
    } else {
      console.log(`Downloading ${url}`);
      const response = await fetch(url, {signal:AbortSignal.timeout(60000)});
      if (!response.ok) throw new Error(`Download failed: HTTP ${response.status}`);
      bytes = Buffer.from(await response.arrayBuffer());
    }
    const digest = createHash('sha256').update(bytes).digest('hex');
    if (digest !== target.sha256) throw new Error('love-thorvg checksum mismatch; nothing was installed.');
    const zip = join(staging, 'release.zip');
    const unpacked = join(staging, 'unpacked');
    await writeFile(zip, bytes);
    let extraction;
    if (process.platform === 'win32') {
      extraction = spawnSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command',
        'Expand-Archive -LiteralPath $env:LOVE_DICEBEAR_ZIP -DestinationPath $env:LOVE_DICEBEAR_UNPACKED'],
      {encoding:'utf8', env:{...process.env, LOVE_DICEBEAR_ZIP:zip, LOVE_DICEBEAR_UNPACKED:unpacked}});
    } else {
      extraction = spawnSync('unzip', ['-q', zip, '-d', unpacked], {encoding:'utf8'});
    }
    if (extraction.error || extraction.status !== 0) {
      throw new Error(`Could not extract love-thorvg. Install ${process.platform === 'win32' ? 'PowerShell' : 'unzip'}. ${extraction.error?.message || extraction.stderr}`);
    }
    const release = join(unpacked, name);
    const library = join(release, 'love_thorvg');
    await validateRenderer(library, target);
    for (const notice of ['LICENSE', 'THORVG-LICENSE', 'README.md']) {
      await copyFile(join(release, notice), join(library, notice));
    }
    await writeFile(join(library, '.love-dicebear-release'), `${version}\n${digest}\n`);
    // Do not replace a manually installed renderer or another concurrent setup.
    if (await exists(destination)) throw new Error('love_thorvg/ appeared during setup; leaving it unchanged.');
    await rename(library, destination);
    console.log(`Installed love-thorvg ${version} (${target.name}); checksum verified.`);
  } finally {
    await rm(staging, {recursive:true, force:true});
  }
}

export async function findLove(env = process.env) {
  const executable = process.platform === 'win32' ? 'love.exe' : 'love';
  const searchPath = (name) => (env.PATH || '').split(delimiter).filter(Boolean).map(path => join(path, name));
  let candidates;
  if (env.LOVE) {
    candidates = isAbsolute(env.LOVE) || env.LOVE.includes('/') || env.LOVE.includes('\\')
      ? [resolve(env.LOVE)] : searchPath(env.LOVE);
  } else {
    candidates = searchPath(executable);
    if (process.platform === 'darwin') candidates.push('/Applications/love.app/Contents/MacOS/love');
    if (process.platform === 'win32' && env.ProgramFiles) candidates.push(join(env.ProgramFiles, 'LOVE', 'love.exe'));
  }
  for (const candidate of candidates) {
    try { await access(candidate, constants.X_OK); return candidate; } catch {}
  }
  throw new Error('LÖVE was not found. Install LÖVE 11.x from https://love2d.org or set LOVE to its executable path.');
}

export function rendererFor(args) {
  if (args.includes('--http-test')) return 'http';
  const index = args.indexOf('--renderer');
  const renderer = index < 0 ? 'thorvg' : args[index + 1];
  if (!['thorvg','http'].includes(renderer)) throw new Error('--renderer must be thorvg or http');
  return renderer;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--help')) {
    console.log('npm run dev                 Install renderer if missing, then launch LÖVE\n'
      + 'npm run setup               Install renderer without launching\n'
      + 'npm run dev -- --render-test Run native rendering checks\n'
      + 'npm run dev -- --style initials --font examples/fonts/Abel-Regular.ttf  Preview SVG text (updated ThorVG required)\n'
      + 'npm run dev -- --renderer http Use API PNGs (requires curl; skips ThorVG setup)\n'
      + 'npm run dev -- --renderer http --cache Enable URL-keyed PNG caching\n'
      + 'LOVE=/path/to/love          Override the LÖVE executable\n'
      + 'LOVE_THORVG_ARCHIVE=/file.zip Use a downloaded release (checksum verified)');
    return;
  }
  const setup = args[0] === '--setup';
  if (setup && args.length > 1) throw new Error('--setup does not take additional arguments.');
  const executable = setup ? undefined : await findLove();
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  if (setup || rendererFor(args) === 'thorvg') await ensureRenderer(root);
  else {
    const curl = spawnSync(process.platform === 'win32' ? 'curl.exe' : 'curl', ['--version'], {encoding:'utf8'});
    if (curl.error || curl.status !== 0) throw new Error('HTTP mode requires curl on PATH. Install curl, then run npm run dev again.');
    console.log('Using HTTP PNG rendering; ThorVG is not required.');
  }
  if (setup) return;
  console.log(`Starting ${executable}`);
  const child = spawnSync(executable, [root, ...args], {cwd:root, stdio:'inherit'});
  if (child.error) throw child.error;
  process.exitCode = child.status ?? 1;
}

const entry = process.argv[1] && await realpath(resolve(process.argv[1])).catch(() => null);
if (entry && import.meta.url === pathToFileURL(entry).href) {
  main().catch(error => { console.error(error.message); process.exitCode = 1; });
}
