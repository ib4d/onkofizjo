/* Demo-only bridge. Production will replace this with authenticated API calls. */
(async function () {
  if (!location.pathname.includes('patient.html')) return;
  const path = location.pathname.includes('patient') ? 'data/demo-patient.json' : 'data/demo-patient.json';
  try {
    const result = await OnkofizjoApi.get('/api/patients', path);
    const requestedId = new URLSearchParams(location.search).get('patientId');
    const patients = result.data.patients || [result.data];
    const patient = patients.find(item => item.id === requestedId) || patients[0];
    const [firstName, ...lastNames] = (patient.name || '').split(' ');
    document.querySelectorAll('body *').forEach((node) => {
      if (node.children.length !== 0) return;
      if (node.textContent.includes('Anna Kowalska')) node.textContent = node.textContent.replaceAll('Anna Kowalska', patient.name);
      else if (node.textContent.trim() === 'Anna') node.textContent = firstName;
      else if (node.textContent.trim() === 'Kowalska') node.textContent = lastNames.join(' ');
    });
    const banner = document.createElement('div');
    banner.textContent = `DEMO DATA · ${result.source} · No real patient information`;
    banner.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
    document.body.appendChild(banner);
    const notesResult = await OnkofizjoApi.get('/api/notes', 'data/demo-notes.json');
    const notes = notesResult.data.notes || [];
    const panel = document.createElement('section');
    panel.setAttribute('aria-label', 'Clinical notes');
    panel.className = 'crm-overlay-card';
    panel.innerHTML = `<div style="display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #d9d1c7;padding-bottom:10px;margin-bottom:4px"><div style="font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:#79564f">Clinical notes · ${notes.length}</div><button type="button" aria-label="Close clinical notes" data-close-overlay style="border:0;background:transparent;color:#79564f;font-size:20px;line-height:1;cursor:pointer;padding:2px 5px">×</button></div>` +
      (notes.length ? notes.slice().reverse().map(note => `<article style="padding:12px 0;border-top:1px solid #d9d1c7"><div style="font:600 13px Inter,Arial,sans-serif;color:#051a0f">${note.author || 'Gosia'} · ${note.status || 'RECORDED'}</div><div style="font:14px Inter,Arial,sans-serif;line-height:1.5;color:#4d514e;margin-top:5px">${note.text || ''}</div><div style="font:12px Inter,Arial,sans-serif;color:#737973;margin-top:5px">${note.createdAt || 'Draft'} · human review required</div></article>`).join('') : '<p style="font:14px Inter,Arial,sans-serif;color:#737973">No clinical notes recorded.</p>');
    panel.style.cssText = 'position:fixed;right:20px;bottom:20px;z-index:9998;width:min(360px,calc(100vw - 40px));max-height:42vh;overflow:auto;background:#fffdf9;border:1px solid #d9d1c7;border-radius:14px;padding:16px;box-shadow:0 18px 45px rgba(5,26,15,.14);opacity:1;transform:translateY(0);transition:opacity .28s ease,transform .28s ease';
    document.body.appendChild(panel);
    let closeTimer;
    const close = () => { panel.style.opacity = '0'; panel.style.transform = 'translateY(12px)'; panel.style.pointerEvents = 'none'; window.setTimeout(() => panel.remove(), 300); };
    const scheduleClose = () => { window.clearTimeout(closeTimer); closeTimer = window.setTimeout(close, 8000); };
    panel.querySelector('[data-close-overlay]').addEventListener('click', close);
    panel.addEventListener('mouseenter', () => window.clearTimeout(closeTimer));
    panel.addEventListener('mouseleave', scheduleClose);
    panel.addEventListener('touchstart', () => window.clearTimeout(closeTimer), { passive: true });
    panel.addEventListener('touchend', scheduleClose, { passive: true });
    scheduleClose();
  } catch (error) {
    console.warn('Demo data unavailable', error);
  }
})();
