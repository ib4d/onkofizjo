(async function () {
  const selectedId = new URLSearchParams(location.search).get('patientId');
  if (!selectedId) return;
  try {
    const response = await fetch(`http://127.0.0.1:8797/api/patients?context=${encodeURIComponent(selectedId)}`, { cache: 'no-store' });
    const data = await response.json();
    const patient = (data.patients || []).find(item => item.id === selectedId);
    if (!patient) throw new Error('Patient not found');
    const profiles = {
      'demo-patient-anna-kowalska': { age:'54', id:'PAC-2023-089', tag:'Onkologia', state:'Aktywna Terapia', measure:'Elewacja ramienia (P)', value:'110°', symptom:'Obrzęk limfatyczny', detail:'Lekki obrzęk przedramienia prawego, nasilający się wieczorem.', insight:'Na podstawie ograniczonej rotacji zewnętrznej i przebytej radioterapii, sugeruję wdrożenie delikatnych technik powięziowych.' },
      'demo-patient-maria-nowak': { age:'46', id:'PAC-2024-014', tag:'Dietetyka', state:'Plan żywieniowy', measure:'Realizacja planu', value:'72%', symptom:'Zmęczenie po posiłkach', detail:'Pacjentka zgłasza spadek energii po południu; wymaga przeglądu regularności posiłków.', insight:'Na podstawie celu dietetycznego i zapisów posiłków sugeruję przegląd rozkładu energii oraz nawodnienia.' },
      'demo-patient-ewa-dabrowska': { age:'39', id:'PAC-2024-027', tag:'Fizjoterapia', state:'Rehabilitacja aktywna', measure:'Zakres ruchu barku', value:'145°', symptom:'Ograniczenie ruchowe', detail:'Ograniczenie zakresu ruchu po stronie lewej; monitorować tolerancję ćwiczeń.', insight:'Na podstawie ostatniej oceny ruchowej sugeruję progresję ćwiczeń aktywnych zgodnie z tolerancją.' }
    };
    const contextResponse = await fetch(`http://127.0.0.1:8797/api/patient-context?patientId=${encodeURIComponent(selectedId)}`, { cache: 'no-store' });
    const contextData = await contextResponse.json();
    const fields = contextData.profiles?.[selectedId];
    if (!fields) throw new Error(`Clinical context not found: ${selectedId}`);
    const names = (patient.name || '').split(' ');
    const main = document.querySelector('main');
    if (main) {
      const headers = [...main.children].filter(child => child.tagName === 'HEADER');
      main.innerHTML = '';
      headers.forEach(header => main.appendChild(header));
      const view = document.createElement('section');
      view.style.cssText = 'max-width:1180px;margin:0 auto;padding:32px 5vw 80px;font-family:Inter,Arial,sans-serif;color:#1c1c19';
      view.innerHTML = `<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:20px;flex-wrap:wrap"><div><div style="font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:#79564f">Clinical record · ${patient.ecosystem.replaceAll('_',' ')}</div><h1 style="font:48px Georgia,serif;color:#051a0f;margin:12px 0">${patient.name}</h1><p style="color:#737973">Wiek: ${fields.age} · ID: ${fields.recordId} · ${patient.location.replaceAll('_',' ')}</p></div><span style="padding:10px 14px;border:1px solid #d9d1c7;border-radius:999px;color:#051a0f">${fields.tag}</span></div><div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin-top:26px"><article style="background:#fff;border:1px solid #d9d1c7;border-radius:12px;padding:22px"><div style="font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#79564f">Current care state</div><h2 style="font:26px Georgia,serif;color:#051a0f">${fields.state}</h2><p style="color:#4d514e;line-height:1.5">${fields.detail}</p></article><article style="background:#fff;border:1px solid #d9d1c7;border-radius:12px;padding:22px"><div style="font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#79564f">Primary measure</div><h2 style="font:26px Georgia,serif;color:#051a0f">${fields.measure}</h2><strong style="font-size:34px;color:#bd9b60">${fields.value}</strong></article><article style="background:#fff;border:1px solid #d9d1c7;border-radius:12px;padding:22px"><div style="font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#79564f">Reported symptom</div><h2 style="font:26px Georgia,serif;color:#051a0f">${fields.symptom}</h2><p style="color:#4d514e;line-height:1.5">${fields.detail}</p></article></div><article style="margin-top:16px;background:#faf8f5;border:1px solid #e8dfd5;border-radius:12px;padding:22px"><div style="font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#79564f">Hermes · draft insight</div><p style="font-size:18px;line-height:1.6;color:#051a0f">${fields.insight}</p><small style="color:#737973">Synthetic demo context · human review required</small></article>`;
      main.appendChild(view);
      return;
    }
    const initials = names.map(name => name[0]).join('');
    const avatarSvg = `data:image/svg+xml,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="800" height="420" viewBox="0 0 800 420"><rect width="800" height="420" fill="#e8dfd5"/><circle cx="400" cy="170" r="92" fill="#bd9b60" opacity=".75"/><text x="400" y="195" text-anchor="middle" font-family="Georgia" font-size="88" fill="#051a0f">${initials}</text><text x="400" y="340" text-anchor="middle" font-family="Arial" font-size="24" fill="#051a0f">DEMO PROFILE</text></svg>`)}`;
    document.querySelectorAll('img[alt*="Anna"], img[alt*="Therapist Profile"], img[alt*="Avatar"]').forEach(img => { img.src = avatarSvg; img.alt = `${patient.name} demo profile`; });
    document.querySelector('main')?.setAttribute('data-patient-id', selectedId);
    document.querySelectorAll('body *').forEach(node => {
      if (node.children.length) return;
      const text = node.textContent.trim();
      if (text === 'Anna') node.textContent = names[0];
      if (text === 'Kowalska') node.textContent = names.slice(1).join(' ');
      if (text === 'Wiek: 54 | ID: PAC-2023-089') node.textContent = `Wiek: ${fields.age} | ID: ${fields.id}`;
      if (text === 'Onkologia' || text === 'Dietetyka' || text === 'Fizjoterapia') node.textContent = fields.tag;
      if (text === 'Aktywna Terapia' || text === 'Plan żywieniowy' || text === 'Rehabilitacja aktywna') node.textContent = fields.state;
      if (text === 'Elewacja ramienia (P)' || text === 'Realizacja planu' || text === 'Zakres ruchu barku') node.textContent = fields.measure;
      if (text === '110°' || text === '72%' || text === '145°') node.textContent = fields.value;
      if (text === 'Obrzęk limfatyczny' || text === 'Zmęczenie po posiłkach' || text === 'Ograniczenie ruchowe') node.textContent = fields.symptom;
      if (text.includes('Lekki obrzęk przedramienia') || text.includes('Pacjentka zgłasza spadek energii') || text.includes('Ograniczenie zakresu ruchu po stronie')) node.textContent = fields.detail;
      if (text.includes('Na podstawie ograniczonej rotacji') || text.includes('Na podstawie celu dietetycznego') || text.includes('Na podstawie ostatniej oceny ruchowej')) node.textContent = fields.insight;
      if (selectedId.includes('maria') && (text.includes('Obrz') || text.includes('Napięcie') || text.includes('NapiÄ™cie'))) node.textContent = fields.symptom;
      if (selectedId.includes('ewa') && (text.includes('Obrz') || text.includes('Napięcie') || text.includes('NapiÄ™cie'))) node.textContent = fields.symptom;
      if (selectedId.includes('maria') && (text.includes('Plan przeciw') || text.includes('75%'))) node.textContent = 'Plan żywieniowy · realizacja 72%';
      if (selectedId.includes('ewa') && (text.includes('Plan przeciw') || text.includes('75%'))) node.textContent = 'Ćwiczenia aktywne · progresja monitorowana';
    });
  } catch (error) { console.warn('Patient context unavailable', error); }
})();
