/* 約診日期推算 — 離線小管家（service worker）
   改版時把 CACHE 版本號往上加一號（例如 cdp-v4），使用者一開就會自動換新版。 */
const CACHE = "cdp-v4";
const ASSETS = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icon-180.png",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-maskable-512.png"
];

// 安裝：把整個 App 影印一份收進手機
self.addEventListener("install", function(e){
  e.waitUntil(
    caches.open(CACHE).then(function(c){ return c.addAll(ASSETS); })
      .then(function(){ return self.skipWaiting(); })
  );
});

// 啟用：清掉舊版本的快取
self.addEventListener("activate", function(e){
  e.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.filter(function(k){ return k !== CACHE; })
        .map(function(k){ return caches.delete(k); }));
    }).then(function(){ return self.clients.claim(); })
  );
});

// 取用：先找手機裡的存檔（離線也能開），沒有再連網；連網失敗就退回首頁
self.addEventListener("fetch", function(e){
  if (e.request.method !== "GET") return;
  e.respondWith(
    caches.match(e.request).then(function(hit){
      return hit || fetch(e.request).catch(function(){ return caches.match("./index.html"); });
    })
  );
});
