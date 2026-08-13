/* Shared client boundary. Production will add auth headers and request policies here. */
(function (global) {
  const API_BASE = global.ONKOFIZJO_API_BASE || 'http://127.0.0.1:8794';
  async function get(path, fallbackPath) {
    try {
      const response = await fetch(`${API_BASE}${path}`, { headers: { Accept: 'application/json' } });
      if (response.ok) return { data: await response.json(), source: 'development-api' };
    } catch (error) { console.warn('Development API unavailable', error); }
    const fallback = await fetch(fallbackPath);
    return { data: await fallback.json(), source: 'local-demo-json' };
  }
  async function post(path, payload) {
    const response = await fetch(`${API_BASE}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify(payload) });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'Request failed');
    return { data, source: 'development-api' };
  }
  global.OnkofizjoApi = { API_BASE, get, post };
})(window);
