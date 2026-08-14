/* Demo-only bridge for the Stitch diet and Hermes screens. */
(async function () {
  const results = await Promise.all([
    OnkofizjoApi.get('/api/diet-plans', 'data/demo-diet-plan.json'),
    OnkofizjoApi.get('/api/assistant-runs', 'data/demo-assistant-run.json')
  ]);
  const plan = results[0].data;
  const run = results[1].data;
  const patientId = new URLSearchParams(location.search).get('patientId') || plan.patientId;
  try {
    const patientResult = await OnkofizjoApi.get('/api/patients', 'data/demo-patients.json');
    const patient = (patientResult.data.patients || []).find(item => item.id === patientId);
    if (patient) document.querySelectorAll('body *').forEach(node => { if (node.children.length === 0 && node.textContent.trim() === 'Anna Kowalska') node.textContent = patient.name; });
  } catch (error) { console.warn('Diet patient context unavailable', error); }
  const marker = document.createElement('div');
  marker.textContent = `DEMO DATA · ${results[0].source} · ${plan.status} · HUMAN REVIEW REQUIRED`;
  marker.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
  document.body.appendChild(marker);
  const actionButtons = [...document.querySelectorAll('button')].filter(button => /Zapisz|Zatwierd|Generuj|Przejdź|PrzejdĹş|Generuj Ponownie/i.test(button.textContent));
  actionButtons.forEach(button => button.addEventListener('click', async () => {
    const result = await OnkofizjoApi.post('/api/diet-plans', { patientId, requestedBy: 'demo-gosia', action: button.textContent.trim(), humanApprovalRequired: true });
    marker.textContent = `DEMO DATA · ${result.source} · ${result.data.status} · PATIENT ${patientId} · HUMAN REVIEW REQUIRED`;
  }));
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
