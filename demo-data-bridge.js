/* Demo-only bridge. Production will replace this with authenticated API calls. */
(async function () {
  const path = location.pathname.includes('patient') ? 'data/demo-patient.json' : 'data/demo-patient.json';
  try {
    const response = await fetch(path);
    if (!response.ok) return;
    const patient = await response.json();
    document.querySelectorAll('body *').forEach((node) => {
      if (node.children.length === 0 && node.textContent.includes('Anna Kowalska')) {
        node.textContent = node.textContent.replaceAll('Anna Kowalska', patient.name);
      }
    });
    const banner = document.createElement('div');
    banner.textContent = 'DEMO DATA · No real patient information';
    banner.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
    document.body.appendChild(banner);
  } catch (error) {
    console.warn('Demo data unavailable', error);
  }
})();
