/* Let Zensical replace page content; preserve the reader's desktop menu position. */
(() => {
  if (window.__dicebearSidebarInstalled || typeof document$ === 'undefined') return;
  window.__dicebearSidebarInstalled = true;
  let pending = null;
  const scrollwrap = () => document.querySelector('.md-sidebar--primary .md-sidebar__scrollwrap');
  const remember = () => {
    if (matchMedia('(min-width: 76.25em)').matches) pending = scrollwrap()?.scrollTop ?? null;
  };
  document.addEventListener('click', event => {
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const link = event.target.closest('a[href]');
    if (!link || link.hasAttribute('download') || (link.target && link.target !== '_self')) return;
    const next = new URL(link.href, location.href);
    if (next.origin === location.origin && next.pathname !== location.pathname) remember();
  }, true);
  window.addEventListener('popstate', remember);
  document$.subscribe(() => {
    if (pending === null) return;
    const position = pending;
    pending = null;
    // Run after the theme mounts the new sidebar and positions its active entry.
    requestAnimationFrame(() => {
      const element = scrollwrap();
      if (element) element.scrollTop = position;
    });
  });
})();
