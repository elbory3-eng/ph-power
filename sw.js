const CACHE_NAME = "phpower-v9";
const ASSETS = [
  "./",
  "./index.html",
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png",
  "./icon.svg",
  "./img/ej/curl-barra.webp",
  "./img/ej/curl-martillo.webp",
  "./img/ej/dominadas.webp",
  "./img/ej/elevaciones-laterales.webp",
  "./img/ej/face-pull.webp",
  "./img/ej/giro-ruso.webp",
  "./img/ej/hip-thrust.webp",
  "./img/ej/jalon-pecho.webp",
  "./img/ej/landmine.webp",
  "./img/ej/peso-muerto-rumano.webp",
  "./img/ej/peso-muerto.webp",
  "./img/ej/plancha.webp",
  "./img/ej/prensa.webp",
  "./img/ej/press-banca.webp",
  "./img/ej/press-inclinado.webp",
  "./img/ej/press-militar.webp",
  "./img/ej/remo-barra.webp",
  "./img/ej/remo-sentado.webp",
  "./img/ej/sentadilla-salto.webp",
  "./img/ej/sentadilla.webp",
  "./img/ej/triceps-polea.webp",
  "./img/ej/zancadas.webp"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      const fetchPromise = fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseClone);
            });
          }
          return networkResponse;
        })
        .catch(() => cachedResponse);

      return cachedResponse || fetchPromise;
    })
  );
});
