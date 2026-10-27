// Registriert den Service Worker der PWA (erzeugt von tool/generate_sw.py) und
// blendet den Ladehinweis aus, sobald Flutter den ersten Frame gezeichnet hat.
// Eigene Datei statt Inline-Skript, weil die Content-Security-Policy nur 'self' erlaubt.
(function () {
  // Ladehinweis weich ausblenden (200 ms Deckkraft), dann aus dem DOM nehmen,
  // damit Screenreader ihn nicht weiter vorlesen.
  window.addEventListener('flutter-first-frame', function () {
    var lade = document.getElementById('lade');
    if (!lade) return;
    lade.classList.add('weg');
    setTimeout(function () { lade.remove(); }, 260);
  }, { once: true });

  if (!('serviceWorker' in navigator)) return;
  window.addEventListener('load', function () {
    var base = document.querySelector('base');
    var href = (base && base.getAttribute('href')) || './';
    navigator.serviceWorker.register(new URL('sw.js', new URL(href, location.href)).href).catch(function (e) {
      console.warn('Service Worker konnte nicht registriert werden:', e);
    });
  });
})();
