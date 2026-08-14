(async function () {
  const patientId = new URLSearchParams(location.search).get('patientId') || 'demo-patient-anna-kowalska';
  const action = [...document.querySelectorAll('button')].find(button => /Nowe Zapytanie/i.test(button.textContent));
  if (!action) return;
  action.addEventListener('click', async () => {
    const task = window.prompt('Describe la tarea para Hermes');
    if (!task) return;
    const response = await OnkofizjoApi.post('/api/assistant-runs', { patientId, task, sources: ['patient-context'], requestedBy: 'demo-gosia' });
    const notice = document.createElement('p');
    notice.textContent = `${response.data.status} · revisión humana requerida · ${response.data.answer}`;
    notice.style.cssText = 'position:fixed;right:20px;bottom:20px;z-index:9999;max-width:420px;background:#fffdf9;border:1px solid #d9d1c7;border-radius:10px;padding:16px;color:#051a0f;box-shadow:0 12px 30px rgba(5,26,15,.15)';
    document.body.appendChild(notice);
    setTimeout(() => notice.remove(), 9000);
  });
})();
