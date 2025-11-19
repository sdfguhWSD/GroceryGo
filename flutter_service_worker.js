'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "f577070897b5618549aa13c65408cb6e",
"assets/AssetManifest.bin.json": "2b2c349a680909c102c65c9df291f107",
"assets/AssetManifest.json": "2ceb266067f66f6425d4a0ea99a28c79",
"assets/assets/image/56.png": "377f5e921a22c6e0ef2bc8035cbd0aef",
"assets/assets/image/b1.png": "2a1bc739c2b751b988eb5ce7fda0904d",
"assets/assets/image/b2.png": "a32f0bf05d06550fc18ef3d41e19b33b",
"assets/assets/image/b3.png": "4ac8bd65a01764981faf2d80ed700380",
"assets/assets/image/b4.png": "2244d3af4d3c10c16d92b2fe7191a7f4",
"assets/assets/image/b5.png": "6bf5a85dda75266eed34431c9494ba0c",
"assets/assets/image/bk1.png": "8f9872cb3453ea99d2080f99792b7342",
"assets/assets/image/bk2.png": "48bbc998662eef3adc19c3c15cf1310a",
"assets/assets/image/bk3.png": "7d0ed0df257b60f28a4af48247a6c9d5",
"assets/assets/image/bk4.png": "7755601c915e88258056a2b4192390cf",
"assets/assets/image/bk5.png": "05a514c8e9bc4e8f85a41419232d7937",
"assets/assets/image/cat1.png": "00874cbadef4bbf0111bdb2cf8bad455",
"assets/assets/image/cat2.png": "7ddbd71e4caba1444ecfb3cbf8a162d2",
"assets/assets/image/cat3.png": "985db0e484d4e5d06ea166fdd96339c6",
"assets/assets/image/cat4.png": "de06dc7ab2dfdbabe9c0516fb574be3f",
"assets/assets/image/cat5.png": "93bb533e7c03c89a20af484515256f8e",
"assets/assets/image/cat6.png": "dfb1fd41fd1ab1d96172afc39af41c86",
"assets/assets/image/cat7.png": "a033ce63b6a6533843b5930a72374dd6",
"assets/assets/image/cat8.png": "29726dc2d909458219f3e5c62a309ed8",
"assets/assets/image/d1.png": "bd14f4fcebfad340512959c3e3f524a9",
"assets/assets/image/d2.png": "a82c2f5f0007c0c0e8867707edc9e243",
"assets/assets/image/d3.png": "d2254219f465a30e3b7e5919d5eed02a",
"assets/assets/image/d4.png": "73cad4061bfef12041c9f1a5c30aa4eb",
"assets/assets/image/d5.png": "feb0a44b9c24650bccdd01c1480f6c35",
"assets/assets/image/e1.png": "3c98861fcc484579dad084c8d03d8d88",
"assets/assets/image/e2.png": "87f095c5b82250d819cb24c6063011e3",
"assets/assets/image/e3.png": "d4334d2187a671873648db93ccda3d2e",
"assets/assets/image/e4.png": "8945bbd93c414a2de22fb5fb2ea4bfc8",
"assets/assets/image/e5.png": "3c7e7e877811389f8421477489ff11e1",
"assets/assets/image/f1.png": "581738bc58110b14eda3b3a5a98b087f",
"assets/assets/image/f2.png": "d450adc652e9a74400ecf8a1f59f8735",
"assets/assets/image/f3.png": "c9c4e122d30754003c3a48f39e49d6a5",
"assets/assets/image/f4.png": "40330cba519086813d286debe7a1ea67",
"assets/assets/image/f5.png": "23547bb0cb50e301688c1ee9c9b02304",
"assets/assets/image/fr1.png": "472e4f4861c87b8e0481b90c3f444bfc",
"assets/assets/image/fr2.png": "93ad2537481d98e2adb6d7e4448c3299",
"assets/assets/image/fr3.png": "f14aff4e060b8e8e54d7a06b0d2baf25",
"assets/assets/image/fr4.png": "e76b65e16da833c74de33f489cb13043",
"assets/assets/image/fr5.png": "a7d430436be6a5f12a58ab495a6d39b8",
"assets/assets/image/gro.png": "01a59c60edeb1aa380d4339bc220a630",
"assets/assets/image/groce1.png": "0ea563fd62bde96af05aa3d59eb7db0c",
"assets/assets/image/groce2.png": "010488be9d125c6cb21232a1bd380ab7",
"assets/assets/image/groce3.png": "5196dc525777fbe0739c0c11b24f6913",
"assets/assets/image/groce4.png": "8db3820f303ffb4ea3e6525c8c53a6cf",
"assets/assets/image/groce5.png": "faf82154f536c4a39d9f73180488d404",
"assets/assets/image/m1.png": "d2d2bdc78ca59cab5f7c6ed12180bb2b",
"assets/assets/image/m2.png": "19a15126635f409e3d29fa6844441af4",
"assets/assets/image/m3.png": "612f95d2d69752313354ccae2e9f6bcd",
"assets/assets/image/m4.png": "09090f963ad2d0f75d7f3ae8e80d3f36",
"assets/assets/image/m5.png": "9534e623af55beff538d3d20393b7985",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "e4d89c3e1f0b6b533d41d6fe5dea5e8b",
"assets/NOTICES": "810159d1b3475a246b2eaec67dcb9818",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "05c2e2ea3cd0a0521ee12160bc1022d8",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "a3e96f17465eb2c588552ca85f8683ad",
"/": "a3e96f17465eb2c588552ca85f8683ad",
"main.dart.js": "c4217bbfdd444c7fca1bd8ccd0dcc6e9",
"manifest.json": "395f97ff849015b2d6115e178c7875ab",
"version.json": "5274d3573a092b784d2450a48c0d2eef"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
