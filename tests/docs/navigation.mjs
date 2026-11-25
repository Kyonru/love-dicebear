import assert from 'node:assert/strict';
import {readFile, mkdir} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {chromium} from 'playwright';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const origin = 'https://kyonru.github.io/love-dicebear/';
const output = path.join(root, 'test-output/docs');
await mkdir(output, {recursive: true});
const browser = await chromium.launch({headless: true});
try {
  const context = await browser.newContext({viewport: {width: 1440, height: 900}});
  const errors = [], missing = [];
  // Exercise the exact Pages base path without publishing a test build or using a server.
  await context.route(origin + '**', async route => {
    let relative = decodeURIComponent(new URL(route.request().url()).pathname.slice('/love-dicebear/'.length));
    if (!relative || relative.endsWith('/')) relative += 'index.html';
    const file = path.resolve(root, 'site', relative);
    if (!file.startsWith(path.join(root, 'site') + path.sep)) return route.abort();
    try { await route.fulfill({path: file}); }
    catch { missing.push(relative); await route.fulfill({status: 404, body: 'Not found'}); }
  });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(origin);
  await page.waitForFunction(() => typeof document$ !== 'undefined');
  await page.evaluate(() => { window.navigationSentinel = 'same-document'; });
  const nav = page.locator('.md-sidebar--primary');
  const links = nav.locator('a.md-nav__link[href]');
  for (const link of await links.all()) {
    if ((await link.getAttribute('href'))?.includes('#')) continue;
    assert.equal(await link.locator('svg').count(), 1, `missing navigation icon: ${await link.innerText()}`);
  }
  await page.screenshot({path: path.join(output, 'overview-desktop.png'), fullPage: true});
  await nav.getByRole('link', {name: 'Core API', exact: true}).click();
  await page.waitForURL(origin + 'api/core/');
  await page.getByRole('heading', {name: 'Core API', exact: true}).waitFor();
  assert.equal(await page.evaluate(() => window.navigationSentinel), 'same-document', 'navigation reloaded the page');
  await page.screenshot({path: path.join(output, 'core-api-desktop.png'), fullPage: true});
  await page.setViewportSize({width: 1440, height: 600});
  const httpLink = nav.getByRole('link', {name: 'HTTP API', exact: true});
  await httpLink.scrollIntoViewIfNeeded();
  const scrollBefore = await nav.locator('.md-sidebar__scrollwrap').evaluate(el => el.scrollTop);
  await httpLink.click();
  await page.waitForURL(origin + 'api/http/');
  await page.getByRole('heading', {name: 'HTTP API', exact: true}).waitFor();
  const scrollAfter = await nav.locator('.md-sidebar__scrollwrap').evaluate(el => el.scrollTop);
  assert.ok(Math.abs(scrollAfter - scrollBefore) <= 2, `sidebar scroll changed: ${scrollBefore} -> ${scrollAfter}`);
  assert.equal(await page.evaluate(() => window.navigationSentinel), 'same-document');
  await page.goBack();
  await page.getByRole('heading', {name: 'Core API', exact: true}).waitFor();
  assert.equal(await page.evaluate(() => window.navigationSentinel), 'same-document', 'history navigation reloaded');
  await nav.getByRole('link', {name: 'Styles and their options', exact: true}).click();
  await page.locator('article a').filter({hasText: /^bottts$/}).click();
  await page.waitForURL(origin + 'styles/bottts/');
  await page.getByRole('heading', {name: 'bottts', exact: true}).waitFor();
  assert.ok((await page.locator('article').innerText()).includes('eyesVariant'));
  assert.equal(await page.evaluate(() => window.navigationSentinel), 'same-document');
  const mobile = await context.newPage();
  await mobile.setViewportSize({width: 390, height: 844});
  await mobile.goto(origin + 'api/http/');
  await mobile.waitForFunction(() => typeof document$ !== 'undefined');
  await mobile.screenshot({path: path.join(output, 'http-api-mobile.png'), fullPage: true});
  assert.ok(await mobile.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), 'mobile page overflows horizontally');
  await mobile.locator('label[for="__drawer"]').first().click();
  await mobile.screenshot({path: path.join(output, 'navigation-mobile.png')});
  await mobile.locator('.md-sidebar--primary').getByRole('link', {name: 'Avatar options', exact: true}).click();
  await mobile.getByRole('heading', {name: 'Avatar options', exact: true}).waitFor();
  assert.deepEqual(errors, [], 'browser errors');
  assert.deepEqual(missing, [], 'missing built assets');
  console.log('PASS: icons, instant navigation, sidebar scroll, browser history, style references and mobile layout');
} finally {
  await browser.close();
}
