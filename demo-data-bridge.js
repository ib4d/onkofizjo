/* Demo-only bridge. Production will replace this with authenticated API calls. */
(async function () {
  const path = location.pathname.includes('patient') ? 'data/demo-patient.json' : 'data/demo-patient.json';
  try {
    const result = await OnkofizjoApi.get('/api/patients', path);
    const patient = result.data;
    document.querySelectorAll('body *').forEach((node) => {
      if (node.children.length === 0 && node.textContent.includes('Anna Kowalska')) {
        node.textContent = node.textContent.replaceAll('Anna Kowalska', patient.name);
      }
    });
    const banner = document.createElement('div');
    banner.textContent = `DEMO DATA · ${result.source} · No real patient information`;
    banner.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
    document.body.appendChild(banner);
    const notesResult = await OnkofizjoApi.get('/api/notes', 'data/demo-notes.json');
    const notes = notesResult.data.notes || [];
    const panel = document.createElement('section');
    panel.setAttribute('aria-label', 'Clinical notes');
    panel.innerHTML = `<div style="font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:#79564f;margin-bottom:8px">Clinical notes · ${notes.length}</div>` +
      (notes.length ? notes.slice().reverse().map(note => `<article style="padding:12px 0;border-top:1px solid #d9d1c7"><div style="font:600 13px Inter,Arial,sans-serif;color:#051a0f">${note.author || 'Gosia'} · ${note.status || 'RECORDED'}</div><div style="font:14px Inter,Arial,sans-serif;line-height:1.5;color:#4d514e;margin-top:5px">${note.text || ''}</div><div style="font:12px Inter,Arial,sans-serif;color:#737973;margin-top:5px">${note.createdAt || 'Draft'} · human review required</div></article>`).join('') : '<p style="font:14px Inter,Arial,sans-serif;color:#737973">No clinical notes recorded.</p>');
    panel.style.cssText = 'position:fixed;right:20px;bottom:20px;z-index:9998;width:min(360px,calc(100vw - 40px));max-height:42vh;overflow:auto;background:#fffdf9;border:1px solid #d9d1c7;border-radius:14px;padding:16px;box-shadow:0 18px 45px rgba(5,26,15,.14)';
    document.body.appendChild(panel);
  } catch (error) {
    console.warn('Demo data unavailable', error);
  }
})();
