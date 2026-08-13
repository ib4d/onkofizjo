/* Demo-only bridge for the Stitch diet and Hermes screens. */
(async function () {
  const files = await Promise.all([
    fetch('data/demo-diet-plan.json').then((r) => r.json()),
    fetch('data/demo-assistant-run.json').then((r) => r.json())
  ]);
  const [plan, run] = files;
  const marker = document.createElement('div');
  marker.textContent = `DEMO DATA · ${plan.status} · HUMAN REVIEW REQUIRED`;
  marker.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
  document.body.appendChild(marker);
  document.querySelectorAll('body *').forEach((node) => {
    if (node.children.length !== 0) return;
    const value = node.textContent.trim();
    if (value === 'Anna Kowalska') node.textContent = 'Anna Kowalska';
    if (value === 'Propozycja') node.textContent = plan.status === 'ASSISTANT_PROPOSED' ? 'Hermes draft · review required' : value;
    if (value.includes('ESPEN 2021')) node.textContent = 'Source placeholder · verify before clinical use';
  });
  if (location.pathname.includes('hermes')) {
    const heading = [...document.querySelectorAll('h1,h2,h3')].find((x) => x.textContent.includes('Hermes'));
    if (heading) heading.insertAdjacentHTML('afterend', `<p style="margin:12px 0;color:#79564f;font:600 14px Inter,Arial,sans-serif">${run.answer} · ${run.status}</p>`);
  }
})();
