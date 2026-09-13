/* Generated into the release site with a content-hashed application manifest. */
const ASSETS = __ASSETS__;
const BASE = new URL('./', self.location.href);
// Cache Storage is shared by all project sites on the same origin.
const PREFIX = 'simple-pools-app-' + encodeURIComponent(BASE.pathname) + '-';
const CACHE = PREFIX + '__REVISION__';
const URLS = new Set(ASSETS.map(path => new URL(path, BASE).href));

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll([...URLS])));
  // Existing tabs keep their matching app and worker until they close.
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith(PREFIX) && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== BASE.origin || !url.pathname.startsWith(BASE.pathname)) return;
  let key = url.href;
  if (event.request.mode === 'navigate') key = new URL('index.html', BASE).href;
  if (!URLS.has(key)) return;
  event.respondWith((async () => {
    const cached = await (await caches.open(CACHE)).match(key);
    const response = cached || await fetch(event.request);
    if (response.status === 0) return response;
    // GitHub Pages cannot configure these headers. Apply them to both cached
    // and network responses, including the document and database workers.
    const headers = new Headers(response.headers);
    headers.set('Cross-Origin-Opener-Policy', 'same-origin');
    headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
    return new Response(response.body, {
      status: response.status, statusText: response.statusText, headers
    });
  })());
});
