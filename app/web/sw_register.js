// Registriert den Service Worker der PWA (erzeugt von tool/generate_sw.py).
// Eigene Datei statt Inline-Skript, weil die Content-Security-Policy nur 'self' erlaubt.
(function () {
  if (!('serviceWorker' in navigator)) return;
  window.addEventListener('load', function () {
    var base = document.querySelector('base');
    var href = (base && base.getAttribute('href')) || './';
    navigator.serviceWorker.register(new URL('sw.js', new URL(href, location.href)).href).catch(function (e) {
      console.warn('Service Worker konnte nicht registriert werden:', e);
    });
  });
})();
