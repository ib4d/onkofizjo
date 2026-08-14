(async function () {
  const selectedId = new URLSearchParams(location.search).get('patientId');
  if (!selectedId) return;
  try {
    const response = await fetch(`http://127.0.0.1:8796/api/patients?context=${encodeURIComponent(selectedId)}`, { cache: 'no-store' });
    const data = await response.json();
    const patient = (data.patients || []).find(item => item.id === selectedId);
    if (!patient) throw new Error('Patient not found');
    const profiles = {
      'demo-patient-anna-kowalska': { age:'54', id:'PAC-2023-089', tag:'Onkologia', state:'Aktywna Terapia', measure:'Elewacja ramienia (P)', value:'110°', symptom:'Obrzęk limfatyczny', detail:'Lekki obrzęk przedramienia prawego, nasilający się wieczorem.', insight:'Na podstawie ograniczonej rotacji zewnętrznej i przebytej radioterapii, sugeruję wdrożenie delikatnych technik powięziowych.' },
      'demo-patient-maria-nowak': { age:'46', id:'PAC-2024-014', tag:'Dietetyka', state:'Plan żywieniowy', measure:'Realizacja planu', value:'72%', symptom:'Zmęczenie po posiłkach', detail:'Pacjentka zgłasza spadek energii po południu; wymaga przeglądu regularności posiłków.', insight:'Na podstawie celu dietetycznego i zapisów posiłków sugeruję przegląd rozkładu energii oraz nawodnienia.' },
      'demo-patient-ewa-dabrowska': { age:'39', id:'PAC-2024-027', tag:'Fizjoterapia', state:'Rehabilitacja aktywna', measure:'Zakres ruchu barku', value:'145°', symptom:'Ograniczenie ruchowe', detail:'Ograniczenie zakresu ruchu po stronie lewej; monitorować tolerancję ćwiczeń.', insight:'Na podstawie ostatniej oceny ruchowej sugeruję progresję ćwiczeń aktywnych zgodnie z tolerancją.' }
    };
    const fields = profiles[selectedId] || profiles['demo-patient-anna-kowalska'];
    const names = (patient.name || '').split(' ');
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
    });
  } catch (error) { console.warn('Patient context unavailable', error); }
})();
