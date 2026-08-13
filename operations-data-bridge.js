/* Demo-only bridge for documents and payments. */
(async function () {
  try {
    const result = await OnkofizjoApi.get('/api/operations', 'data/demo-operations.json');
    const data = result.data;
    const banner = document.createElement('div');
    banner.textContent = `DEMO DATA · ${result.source} · DOCUMENTS AND PAYMENTS`;
    banner.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
    document.body.appendChild(banner);
    const labels = [...document.querySelectorAll('body *')].filter((node) => node.children.length === 0);
    labels.forEach((node) => {
      if (node.textContent.includes('Review Diet Plan')) node.textContent = 'Review Meal Plan · Pending';
      if (node.textContent.includes('View All (4)')) node.textContent = `View All (${data.documents.length})`;
      if (node.textContent.includes('Book Appointment')) node.textContent = 'New appointment';
    });
  } catch (error) { console.warn('Demo operations unavailable', error); }
})();
