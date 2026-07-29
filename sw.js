/* 約診日期推算 — 離線小管家（service worker）
   改版時把 CACHE 版本號往上加一號（例如 cdp-v4），使用者一開就會自動換新版。 */
const CACHE = "cdp-v9";
const ASSETS = [
  "./",
  "./index.html",
  "./sheet.html",
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

// 從網址取出檔名，對回存檔的鍵（存檔的鍵沒有 ?d=... 這種參數）
function assetKey(url){
  var p = new URL(url).pathname;
  var f = p.substring(p.lastIndexOf("/") + 1);
  return "./" + (f || "index.html");
}

// 取用：
//   網頁本體（.html）→ **先連網**，連不到才用存檔。
//   ⚠️ 2026-07-29 踩到：原本網頁也是「先用存檔」，結果改版推上線後，
//      使用者一直重新整理都還是舊版（存檔沒過期就永遠不會去連網），
//      要清快取才看得到新版。改成先連網後，改版重新整理就會是新的。
//   圖示、manifest 這類不會變的檔案 → 維持先用存檔，快又省流量。
self.addEventListener("fetch", function(e){
  if (e.request.method !== "GET") return;

  var isPage = e.request.mode === "navigate"
            || e.request.destination === "document"
            || /\.html$/.test(new URL(e.request.url).pathname);

  if (isPage){
    e.respondWith(
      fetch(e.request).then(function(res){
        // 順手把最新的存起來給離線用；帶參數的網址（?d=…）不存，免得存出一堆
        if (!new URL(e.request.url).search){
          var copy = res.clone();
          caches.open(CACHE).then(function(c){ c.put(e.request, copy); });
        }
        return res;
      }).catch(function(){
        // 離線：用存檔頂著。帶參數的網址也對得回同一份檔案
        return caches.match(assetKey(e.request.url)).then(function(hit){
          return hit || caches.match("./index.html");
        });
      })
    );
    return;
  }

  e.respondWith(
    caches.match(e.request).then(function(hit){
      return hit || fetch(e.request).catch(function(){ return caches.match("./index.html"); });
    })
  );
});
