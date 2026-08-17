/* Demo-only bridge for the Stitch diet and Hermes screens. */
(async function () {
  const requestedPatientId = new URLSearchParams(location.search).get('patientId');
  if (!requestedPatientId) {
    document.querySelectorAll('body *').forEach((node) => {
      if (node.children.length === 0 && (node.textContent.includes('Anna Kowalska') || node.textContent.includes('Paciente seleccionado'))) {
        node.textContent = node.textContent.replaceAll('Anna Kowalska', 'Selecciona un paciente').replaceAll('Paciente seleccionado', 'Selecciona un paciente');
      }
    });
    const heading = [...document.querySelectorAll('h1,h2,h3')].find((node) => node.textContent.includes('Kreator Planu'));
    if (heading) heading.insertAdjacentHTML('beforebegin', '<p style="margin:12px 0;color:#79564f;font:600 14px Inter,Arial,sans-serif">Selecciona un paciente desde el CRM para cargar un plan contextualizado.</p>');
    return;
  }
  const results = await Promise.all([
    OnkofizjoApi.get(`/api/diet-plans?patientId=${encodeURIComponent(requestedPatientId)}`, 'data/demo-diet-plan.json'),
    OnkofizjoApi.get('/api/assistant-runs', 'data/demo-assistant-run.json')
  ]);
  const plan = results[0].data;
  const run = results[1].data;
  const patientId = requestedPatientId;
  try {
    const patientResult = await OnkofizjoApi.get('/api/patients', 'data/demo-patients.json');
    const patient = (patientResult.data.patients || []).find(item => item.id === patientId);
    if (patient) document.querySelectorAll('body *').forEach(node => { if (node.children.length === 0 && (node.textContent.includes('Anna Kowalska') || node.textContent.includes('Paciente seleccionado'))) node.textContent = node.textContent.replaceAll('Anna Kowalska', patient.name).replaceAll('Paciente seleccionado', patient.name); });
  } catch (error) { console.warn('Diet patient context unavailable', error); }
  const marker = document.createElement('div');
  marker.textContent = `DEMO DATA · ${results[0].source} · ${plan.status} · HUMAN REVIEW REQUIRED`;
  marker.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:9999;background:#051a0f;color:#fff;padding:8px 12px;border-radius:4px;font:700 11px Inter,Arial,sans-serif;letter-spacing:.08em';
  document.body.appendChild(marker);
  const workflow = document.createElement('section');
  workflow.setAttribute('aria-label', 'Fase 5 diet workflow');
  workflow.style.cssText = 'margin:18px 0;padding:16px;background:#fffdf9;border:1px solid #d9d1c7;border-radius:12px;font:14px Inter,Arial,sans-serif;color:#051a0f';
  workflow.innerHTML = `<strong>Plan contextualizado · ${patientId}</strong><p style="color:#737973;margin:8px 0">Genera una propuesta sintética con restricciones explícitas. Revisión humana obligatoria.</p><label style="display:block;margin:8px 0">Objetivo <input id="phase5-goal" value="${plan.goal || ''}" style="width:100%;padding:9px;border:1px solid #d9d1c7"></label><label style="display:block;margin:8px 0">Restricciones separadas por coma <input id="phase5-restrictions" value="${(plan.restrictions || []).join(', ')}" style="width:100%;padding:9px;border:1px solid #d9d1c7"></label><button id="phase5-generate" style="padding:10px 14px;background:#051a0f;color:white;border:0;border-radius:6px;font-weight:700">Generar propuesta</button><button id="phase5-approve" style="padding:10px 14px;margin-left:8px;border:1px solid #051a0f;background:white;color:#051a0f;border-radius:6px;font-weight:700">Aprobar como Gosia</button><div id="phase5-output" style="margin-top:12px;color:#4d514e"></div>`;
  const anchor = document.querySelector('main') || document.body;
  anchor.prepend(workflow);
  const output = workflow.querySelector('#phase5-output');
  const renderPlan = value => { output.innerHTML = `<strong>${value.status}</strong> · versión ${value.version || 1}<br>${(value.meals || []).map(meal => `${meal.name}: ${meal.description}`).join('<br>')}<br><small>${(value.warnings || []).join(' · ')}</small>`; };
  renderPlan(plan);
  workflow.querySelector('#phase5-generate').onclick = async () => {
    try {
      const goal = workflow.querySelector('#phase5-goal').value.trim();
      const restrictions = workflow.querySelector('#phase5-restrictions').value.split(',').map(x => x.trim()).filter(Boolean);
      const created = await OnkofizjoApi.post('/api/diet-plans', { patientId, goal, restrictions, requestedBy: 'demo-gosia' });
      renderPlan(created.data); marker.textContent = `DEMO DATA · ${created.source} · ${created.data.status} · PATIENT ${patientId} · HUMAN REVIEW REQUIRED`;
    } catch (error) { output.textContent = `No se pudo generar la propuesta: ${error.message}`; }
  };
  workflow.querySelector('#phase5-approve').onclick = async () => {
    try { const approved = await OnkofizjoApi.post('/api/diet-plans/status', { patientId, planId: plan.id || 'demo-plan-created', status: 'APPROVED', approvedBy: 'demo-gosia' }); output.textContent = `Estado registrado: ${approved.data.status}.`; marker.textContent = `DEMO DATA · ${approved.source} · APPROVED · PATIENT ${patientId}`; }
    catch (error) { output.textContent = `No se pudo aprobar: ${error.message}`; }
  };
  const actionButtons = [...document.querySelectorAll('button')].filter(button => /Zapisz|Zatwierd|Generuj|Przejdź|PrzejdĹş|Generuj Ponownie/i.test(button.textContent));
  actionButtons.forEach(button => button.addEventListener('click', async () => {
    const label = button.textContent.trim();
    const status = /Zatwierd/i.test(label) ? 'APPROVED' : /Zapisz/i.test(label) ? 'DRAFT' : 'IN_REVIEW';
    const result = status === 'APPROVED'
      ? await OnkofizjoApi.post('/api/diet-plans/status', { patientId, planId: plan.id || 'demo-plan-created', status, approvedBy: 'demo-gosia' })
      : await OnkofizjoApi.post('/api/diet-plans/status', { patientId, planId: plan.id || 'demo-plan-created', status, actor: 'demo-gosia' });
    marker.textContent = `DEMO DATA · ${result.source} · ${result.data.status} · PATIENT ${patientId} · HUMAN REVIEW REQUIRED`;
  }));
  document.querySelectorAll('body *').forEach((node) => {
    if (node.children.length !== 0) return;
    const value = node.textContent.trim();
    if (value === 'Propozycja') node.textContent = plan.status === 'ASSISTANT_PROPOSED' ? 'Hermes draft · review required' : value;
    if (value.includes('ESPEN 2021')) node.textContent = 'Source placeholder · verify before clinical use';
  });
  if (location.pathname.includes('hermes')) {
    const heading = [...document.querySelectorAll('h1,h2,h3')].find((x) => x.textContent.includes('Hermes'));
    if (heading) heading.insertAdjacentHTML('afterend', `<p style="margin:12px 0;color:#79564f;font:600 14px Inter,Arial,sans-serif">${run.answer} · ${run.status}</p>`);
  }
})();
