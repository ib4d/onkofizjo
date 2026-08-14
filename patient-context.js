(async function () {
  const selectedId = new URLSearchParams(location.search).get('patientId');
  if (!selectedId) return;
  try {
    const base = 'http://127.0.0.1:8797';
    const [patientsResponse, contextResponse] = await Promise.all([
      fetch(`${base}/api/patients?context=${encodeURIComponent(selectedId)}`, { cache: 'no-store' }),
      fetch(`${base}/api/patient-context?patientId=${encodeURIComponent(selectedId)}`, { cache: 'no-store' })
    ]);
    if (!patientsResponse.ok || !contextResponse.ok) throw new Error('Patient API unavailable');
    const patientData = await patientsResponse.json();
    const contextData = await contextResponse.json();
    const patient = (patientData.patients || []).find(item => item.id === selectedId);
    const fields = contextData.profiles?.[selectedId];
    if (!patient || !fields) throw new Error(`Patient context not found: ${selectedId}`);

    const main = document.querySelector('main');
    if (!main) return;
    const headers = [...main.children].filter(child => child.tagName === 'HEADER');
    main.innerHTML = '';
    headers.forEach(header => main.appendChild(header));
    const view = document.createElement('section');
    view.dataset.patientId = selectedId;
    view.style.cssText = 'max-width:1180px;margin:0 auto;padding:32px 5vw 80px;font-family:Inter,Arial,sans-serif;color:#1c1c19';
    const ecosystem = (patient.ecosystem || '').replaceAll('_', ' ');
    const location = (patient.location || '').replaceAll('_', ' ');
    const esc = value => String(value).replace(/[&<>"']/g, character => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[character]));
    view.innerHTML = `<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:20px;flex-wrap:wrap"><div><div style="font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:#79564f">Clinical record · ${esc(ecosystem)}</div><h1 style="font:48px Georgia,serif;color:#051a0f;margin:12px 0">${esc(patient.name)}</h1><p style="color:#737973">Age: ${esc(fields.age)} · ID: ${esc(fields.recordId)} · ${esc(location)}</p></div><span style="padding:10px 14px;border:1px solid #d9d1c7;border-radius:999px;color:#051a0f">${esc(fields.tag)}</span></div><div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:20px"><a href="note-create.html?patientId=${encodeURIComponent(selectedId)}" style="padding:11px 14px;background:#051a0f;color:#fff;text-decoration:none;border-radius:7px;font-weight:700">New clinical note</a><a href="calendar.html?patientId=${encodeURIComponent(selectedId)}" style="padding:11px 14px;border:1px solid #d9d1c7;color:#051a0f;text-decoration:none;border-radius:7px">View appointments</a><a href="teleconsult.html?patientId=${encodeURIComponent(selectedId)}" style="padding:11px 14px;border:1px solid #d9d1c7;color:#051a0f;text-decoration:none;border-radius:7px">Teleconsultation</a></div><div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin-top:26px"><article style="background:#fff;border:1px solid #d9d1c7;border-radius:12px;padding:22px"><div class="eyebrow">Current care state</div><h2>${esc(fields.state)}</h2><p>${esc(fields.detail)}</p></article><article style="background:#fff;border:1px solid #d9d1c7;border-radius:12px;padding:22px"><div class="eyebrow">Primary measure</div><h2>${esc(fields.measure)}</h2><strong class="measure">${esc(fields.value)}</strong></article><article style="background:#fff;border:1px solid #d9d1c7;border-radius:12px;padding:22px"><div class="eyebrow">Reported symptom</div><h2>${esc(fields.symptom)}</h2><p>${esc(fields.detail)}</p></article></div><article style="margin-top:16px;background:#faf8f5;border:1px solid #e8dfd5;border-radius:12px;padding:22px"><div class="eyebrow">Hermes · draft insight</div><p class="insight">${esc(fields.insight)}</p><small>Demo context · human review required</small></article>`;
    const style = document.createElement('style');
    style.textContent = '.eyebrow{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#79564f}.crm-patient-view h2{font:26px Georgia,serif;color:#051a0f}.crm-patient-view p{color:#4d514e;line-height:1.5}.measure{font-size:34px;color:#bd9b60}.insight{font-size:18px;line-height:1.6;color:#051a0f}';
    view.classList.add('crm-patient-view');
    document.head.appendChild(style);
    main.appendChild(view);
  } catch (error) {
    console.warn('Patient context unavailable', error);
  }
})();
