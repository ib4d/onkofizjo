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
  panel.style.cssText = 'margin:12px 0 18px;padding:10px 12px;background:#fffdf9;border:1px solid #d9d1c7;border-radius:10px;box-shadow:0 5px 16px rgba(5,26,15,.05)';
  panel.innerHTML = '<div style="display:flex;align-items:center;justify-content:space-between;gap:12px"><div style="font:700 10px Inter,Arial,sans-serif;letter-spacing:.13em;text-transform:uppercase;color:#79564f;white-space:nowrap">Quick actions</div><div id="quick-links" style="display:flex;flex-wrap:wrap;justify-content:flex-end;gap:6px"></div></div>';
  const target = document.querySelector('main') || document.body;
  target.prepend(panel);
  const grid = panel.querySelector('#quick-links');
  links.forEach(([href, label, icon]) => { const a=document.createElement('a'); a.href=href; a.title=label; a.style.cssText='display:inline-flex;align-items:center;gap:5px;padding:7px 9px;border:1px solid #d9d1c7;border-radius:7px;color:#051a0f;text-decoration:none;font:600 11px Inter,Arial,sans-serif;background:#fff;white-space:nowrap'; a.innerHTML=`<span aria-hidden="true" style="font-size:13px;color:#bd9b60">${icon === 'calendar_month' ? '◷' : icon === 'clinical_notes' ? '▤' : icon === 'restaurant' ? '♢' : icon === 'folder_open' ? '□' : icon === 'videocam' ? '▣' : icon === 'payments' ? '◫' : '✦'}</span><span>${label}</span>`; grid.appendChild(a); });
})();
