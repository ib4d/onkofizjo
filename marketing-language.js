(function () {
  const toggle = [...document.querySelectorAll('button')].find(button => /EN\/PL/i.test(button.textContent));
  if (!toggle) return;
  const current = new URLSearchParams(location.search).get('lang') === 'en' ? 'en' : 'pl';
  toggle.textContent = current === 'en' ? 'PL' : 'EN';
  toggle.addEventListener('click', () => { location.href = `marketing-section.html?section=services&lang=${current === 'en' ? 'pl' : 'en'}`; });
})();
