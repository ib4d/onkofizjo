(async function () {
  if (!location.pathname.endsWith('crm.html')) return;
  const input = document.querySelector('input[placeholder*="Search patients"]');
  if (input) {
    const result = document.createElement('div');
    result.style.cssText = 'position:absolute;top:calc(100% + 8px);left:0;right:0;z-index:80;background:#fffdf9;border:1px solid #d9d1c7;border-radius:10px;box-shadow:0 14px 30px rgba(5,26,15,.12);display:none;overflow:hidden';
    const wrapper = input.parentElement; wrapper.style.position = 'relative'; wrapper.appendChild(result);
    let patients = [];
    try { const response = await OnkofizjoApi.get('/api/patients', 'data/demo-patients.json'); patients = response.data.patients || [response.data]; } catch (_) {}
    const render = () => { const query = input.value.trim().toLowerCase(); if (!query) { result.style.display='none'; return; } const matches = patients.filter(p => `${p.name || ''} ${p.id || ''}`.toLowerCase().includes(query)); result.innerHTML = matches.length ? matches.map(p => `<a href="patient.html" style="display:block;padding:12px 14px;text-decoration:none;color:#051a0f;border-bottom:1px solid #eee8e0;font:600 13px Inter,Arial,sans-serif">${p.name || p.id}<small style="display:block;margin-top:3px;color:#737973;font-weight:400">${p.ecosystem || 'Patient record'}</small></a>`).join('') : '<div style="padding:14px;color:#737973;font:13px Inter,Arial,sans-serif">No patient found.</div>'; result.style.display='block'; };
    input.addEventListener('input', render); input.addEventListener('focus', render); document.addEventListener('click', e => { if (!wrapper.contains(e.target)) result.style.display='none'; });
  }
  const notificationButton = Array.from(document.querySelectorAll('button')).find(button => button.textContent.includes('notifications'));
  if (notificationButton) notificationButton.addEventListener('click', () => {
    const panel = document.createElement('aside'); panel.style.cssText='position:fixed;right:24px;top:78px;z-index:90;width:min(320px,calc(100vw - 32px));padding:16px;background:#fffdf9;border:1px solid #d9d1c7;border-radius:12px;box-shadow:0 18px 40px rgba(5,26,15,.15);opacity:0;transform:translateY(-8px);transition:.25s ease'; panel.innerHTML='<div style="display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #d9d1c7;padding-bottom:10px"><strong style="color:#051a0f">Notifications</strong><button data-close style="border:0;background:none;font-size:20px;cursor:pointer;color:#79564f">×</button></div><p style="font:13px Inter,Arial,sans-serif;line-height:1.5;color:#4d514e">Two care-plan reviews and one consultation note require your attention.</p>'; document.body.appendChild(panel); requestAnimationFrame(()=>{panel.style.opacity='1';panel.style.transform='translateY(0)'}); const close=()=>{panel.style.opacity='0';panel.style.transform='translateY(-8px)';setTimeout(()=>panel.remove(),250)}; panel.querySelector('[data-close]').onclick=close; setTimeout(close,7000); panel.onmouseenter=()=>clearTimeout(panel._timer); panel._timer=setTimeout(close,7000);
  });
  document.addEventListener('click', (event) => { const link = event.target.closest('a[href="patient.html"]'); if (!link) return; const name = link.textContent.trim().split('\n')[0].trim(); const patient = patients.find(item => item.name === name); if (patient) { event.preventDefault(); location.href = `patient.html?patientId=${encodeURIComponent(patient.id)}`; } });
})();
