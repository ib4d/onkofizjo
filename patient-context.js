(async function () {
  const selectedId = new URLSearchParams(location.search).get('patientId');
  if (!selectedId) return;
  try {
    const response = await fetch(`http://127.0.0.1:8796/api/patients?context=${encodeURIComponent(selectedId)}`, { cache: 'no-store' });
    const data = await response.json();
    const patient = (data.patients || []).find(item => item.id === selectedId);
    if (!patient) throw new Error('Patient not found');
    const fields = { age: selectedId.includes('maria') ? '46' : selectedId.includes('ewa') ? '39' : '54', id: selectedId.includes('maria') ? 'PAC-2024-014' : selectedId.includes('ewa') ? 'PAC-2024-027' : 'PAC-2023-089' };
    const names = (patient.name || '').split(' ');
    document.querySelectorAll('body *').forEach(node => {
      if (node.children.length) return;
      const text = node.textContent.trim();
      if (text === 'Anna') node.textContent = names[0];
      if (text === 'Kowalska') node.textContent = names.slice(1).join(' ');
      if (text === 'Wiek: 54 | ID: PAC-2023-089') node.textContent = `Wiek: ${fields.age} | ID: ${fields.id}`;
    });
  } catch (error) { console.warn('Patient context unavailable', error); }
})();
