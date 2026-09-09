// Service Worker that intercepts reel video streaming requests and injects
// auth headers. This allows the HTML <video> element to stream videos from
// authenticated endpoints — the browser handles Range requests natively,
// so playback starts instantly without downloading the entire file.

// Auth headers are passed from the main thread via postMessage.
let authHeaders = {};

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SET_AUTH_HEADERS') {
    authHeaders = event.data.headers || {};
  }
});

self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  // Only intercept requests that contain our streaming marker.
  if (!url.includes('__reel_stream__=1')) {
    return;
  }

  event.respondWith(
    (async () => {
      // Clone the original request's headers and merge auth headers.
      const headers = new Headers(event.request.headers);
      for (const [key, value] of Object.entries(authHeaders)) {
        if (value) {
          headers.set(key, value);
        }
      }

      // Strip the marker param so the server gets a clean URL.
      const cleanUrl = url
        .replace(/([&?])__reel_stream__=1(&?)/, (match, before, after) => {
          return after ? before : (before === '?' ? '' : '');
        });

      const response = await fetch(cleanUrl, {
        method: event.request.method,
        headers: headers,
        credentials: 'same-origin',
      });

      // Return the response as-is — the browser will handle Range
      // requests, Content-Length, and chunked streaming natively.
      return response;
    })()
  );
});

// Activate immediately without waiting for existing clients to close.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
