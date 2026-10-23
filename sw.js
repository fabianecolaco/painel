// Deixa o painel e a página do aluno instaláveis como app. Sempre busca a versão nova na internet;
// a cópia guardada só é usada se o aparelho estiver sem conexão.
const CACHE = "fabi-v11";
self.addEventListener("install", e => { self.skipWaiting(); e.waitUntil(caches.open(CACHE).then(c => c.addAll(["./", "./aluno/", "./favicon.svg", "./icons/icon-192.png"])).catch(() => {})); });
self.addEventListener("activate", e => e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())));
self.addEventListener("fetch", e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET" || u.origin !== location.origin || u.pathname.includes("/docs/")) return;
  // sempre pede a versão nova ao servidor (sem usar o cache do navegador), para as atualizações aparecerem na hora
  const fresh = r.mode === "navigate" ? new Request(r.url, { cache: "no-cache", credentials: "same-origin" }) : new Request(r, { cache: "no-cache" });
  e.respondWith(fetch(fresh).then(res => { if (res.ok) { const cp = res.clone(); caches.open(CACHE).then(c => c.put(r, cp)); } return res; })
    .catch(() => caches.match(r, { ignoreSearch: true }).then(m => m || caches.match(r.mode === "navigate" ? (u.pathname.includes("/aluno/") ? "./aluno/" : "./") : r))));
});
