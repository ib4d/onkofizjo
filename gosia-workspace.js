(function () {
  if (!location.pathname.endsWith('crm.html')) return;
  const links = [
    ['calendar.html', 'Calendar', 'calendar_month'],
    ['patient.html', 'Clinical records', 'clinical_notes'],
    ['diet-plan.html', 'Diet plans', 'restaurant'],
    ['documents.html', 'Documents', 'folder_open'],
    ['teleconsult.html', 'Teleconsultation', 'videocam'],
    ['payments.html', 'Payments', 'payments'],
    ['hermes.html', 'Hermes assistant', 'auto_awesome']
  ];
  const panel = document.createElement('section');
  panel.setAttribute('aria-label', 'Gosia quick workspace');
  panel.style.cssText = 'margin:24px 0;padding:20px;background:#fffdf9;border:1px solid #d9d1c7;border-radius:14px;box-shadow:0 12px 30px rgba(5,26,15,.07)';
  panel.innerHTML = '<div style="font:700 11px Inter,Arial,sans-serif;letter-spacing:.14em;text-transform:uppercase;color:#79564f">Gosia · quick workspace</div><h2 style="margin:8px 0 16px;font:28px Georgia,serif;color:#051a0f">What needs your attention?</h2><div id="quick-links" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px"></div>';
  const target = document.querySelector('main') || document.body;
  target.prepend(panel);
  const grid = panel.querySelector('#quick-links');
  links.forEach(([href, label, icon]) => { const a=document.createElement('a'); a.href=href; a.style.cssText='display:flex;align-items:center;gap:8px;padding:12px;border:1px solid #d9d1c7;border-radius:10px;color:#051a0f;text-decoration:none;font:600 13px Inter,Arial,sans-serif;background:#fff'; a.innerHTML=`<span style="color:#bd9b60">${icon}</span>${label}`; grid.appendChild(a); });
})();
