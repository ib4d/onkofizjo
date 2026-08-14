(function () {
  const patientId = new URLSearchParams(location.search).get('patientId');
  if (!patientId) return;
  if (location.pathname.endsWith('note-create.html')) {
    const select = document.querySelector('#patientId');
    if (select) { const apply = () => { if ([...select.options].some(option => option.value === patientId)) select.value = patientId; }; apply(); new MutationObserver(apply).observe(select, { childList: true }); }
  }
  if (location.pathname.endsWith('teleconsult.html')) {
    const lead = document.querySelector('.lead');
    if (lead) lead.insertAdjacentHTML('afterend', `<p style="color:#79564f;font-weight:700">Patient context: ${patientId}</p>`);
  }
})();
