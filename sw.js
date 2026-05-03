// HolidayQuest Service Worker
// Caches the app shell for offline use
// Network-first strategy for API calls, cache-first for assets

const CACHE_NAME = 'holidayquest-v3';

const PRECACHE = [
  './holidayquest.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  'https://unpkg.com/react@18/umd/react.production.min.js',
  'https://unpkg.com/react-dom@18/umd/react-dom.production.min.js',
  'https://unpkg.com/@babel/standalone/babel.min.js',
  'https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@500;700&display=swap',
];

// Install — precache app shell
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(PRECACHE).catch(err => {
        console.warn('Some precache items failed:', err);
      });
    })
  );
  self.skipWaiting();
});

// Activate — clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// Fetch strategy:
// - Cloudflare Worker API calls → network only (never cache)
// - Everything else → cache first, fallback to network
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Never cache API calls to Cloudflare Worker
  if (url.hostname.includes('workers.dev')) {
    event.respondWith(fetch(event.request));
    return;
  }

  // Cache first for everything else
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        // Cache successful GET responses
        if (event.request.method === 'GET' && response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => {
        // Offline fallback — return cached app shell
        if (event.request.mode === 'navigate') {
          return caches.match('./holidayquest.html');
        }
      });
    })
  );
});
