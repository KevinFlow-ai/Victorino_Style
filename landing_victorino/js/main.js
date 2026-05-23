/* ═══════════════════════════════════════════════════════════════════════════
   main.js — comportamiento de la landing.
   Sin frameworks. Tres responsabilidades:
   1) Resaltar la tarjeta de descarga del SO actual.
   2) Tabs de la sección de capturas.
   3) Animación reveal al entrar en viewport.
   ═══════════════════════════════════════════════════════════════════════════ */

(() => {
  'use strict';

  // ── Año dinámico en el footer ───────────────────────────────────────────
  const anioEl = document.getElementById('year');
  if (anioEl) anioEl.textContent = new Date().getFullYear();

  // ── 1. Detección del sistema operativo ──────────────────────────────────
  // Se usa userAgent + userAgentData (cuando exista) y se marca la tarjeta
  // correspondiente con la clase .is-recommended.
  const detectarPlataforma = () => {
    const ua = (navigator.userAgent || '').toLowerCase();
    const uaPlat = (navigator.userAgentData?.platform || '').toLowerCase();

    if (/android/.test(ua)) return 'android';
    if (/iphone|ipad|ipod/.test(ua)) return 'web'; // iOS sin app nativa → web
    if (/win/.test(uaPlat) || /windows/.test(ua)) return 'windows';
    if (/linux/.test(uaPlat) || (/linux/.test(ua) && !/android/.test(ua))) return 'linux';
    if (/mac/.test(uaPlat) || /macintosh/.test(ua)) return 'web';
    return 'web';
  };

  const plataforma = detectarPlataforma();
  const tarjeta = document.getElementById(`card-${plataforma}`);
  if (tarjeta) tarjeta.classList.add('is-recommended');

  // ── 2. Tabs de la sección de capturas ───────────────────────────────────
  const botonesTab = document.querySelectorAll('.tab-btn');
  const paneles = document.querySelectorAll('.tab-panel');

  // Activar Cliente por defecto.
  const activar = (rol) => {
    botonesTab.forEach(btn => {
      const activo = btn.dataset.tab === rol;
      btn.classList.toggle('bg-primary', activo);
      btn.classList.toggle('text-white', activo);
      btn.classList.toggle('shadow-glow', activo);
      btn.classList.toggle('bg-white', !activo);
      btn.classList.toggle('text-ink', !activo);
      btn.classList.toggle('border', !activo);
      btn.classList.toggle('border-gray-200', !activo);
    });
    paneles.forEach(p => {
      const idEsperado = `panel-${rol}`;
      const activo = p.id === idEsperado;
      p.classList.toggle('active', activo);
      p.classList.toggle('hidden', !activo);
    });
  };

  botonesTab.forEach(btn => {
    btn.addEventListener('click', () => activar(btn.dataset.tab));
  });
  activar('cliente');

  // ── 3. Reveal on scroll ─────────────────────────────────────────────────
  const elementos = document.querySelectorAll('.reveal');

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entradas) => {
      entradas.forEach(entrada => {
        if (entrada.isIntersecting) {
          entrada.target.classList.add('visible');
          observer.unobserve(entrada.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

    elementos.forEach(el => observer.observe(el));
  } else {
    // Fallback: si no hay IntersectionObserver, mostrar todo de golpe.
    elementos.forEach(el => el.classList.add('visible'));
  }
})();
