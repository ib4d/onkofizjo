/* Shared client boundary. Production will add auth headers and request policies here. */
(function (global) {
  if (!document.querySelector('link[data-phase3-responsive]')) {
    const style = document.createElement('link');
    style.rel = 'stylesheet';
    style.href = 'responsive-accessibility.css';
    style.dataset.phase3Responsive = 'true';
    document.head.appendChild(style);
  }
  const API_BASE = global.ONKOFIZJO_API_BASE || 'http://127.0.0.1:8797';
  async function get(path, fallbackPath) {
    try {
      const response = await fetch(`${API_BASE}${path}`, { headers: { Accept: 'application/json' } });
      if (response.ok) return { data: await response.json(), source: 'development-api' };
    } catch (error) { console.warn('Development API unavailable', error); }
    const fallback = await fetch(fallbackPath);
    return { data: await fallback.json(), source: 'local-demo-json' };
  }
  async function post(path, payload) {
    let accessToken = global.sessionStorage.getItem('onkofizjo.demo.accessToken');
    if (!accessToken) {
      const sessionResponse = await fetch(`${API_BASE}/api/auth/session`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify({ userId: 'demo-gosia', role: 'GOSIA' }) });
      if (!sessionResponse.ok) throw new Error('Authentication required');
      const session = await sessionResponse.json();
      accessToken = session.accessToken;
      global.sessionStorage.setItem('onkofizjo.demo.accessToken', accessToken);
    }
    const response = await fetch(`${API_BASE}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'Request failed');
    return { data, source: 'development-api' };
  }
  global.OnkofizjoApi = { API_BASE, get, post };
  if (location.pathname.endsWith('calendar.html')) { const script = document.createElement('script'); script.src = 'calendar-links.js'; document.head.appendChild(script); }
  if (location.pathname.endsWith('note-create.html') || location.pathname.endsWith('teleconsult.html')) { const script = document.createElement('script'); script.src = 'context-route.js'; document.head.appendChild(script); }
})(window);
