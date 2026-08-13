/* Shared client boundary. Production will add auth headers and request policies here. */
(function (global) {
  async function get(path, fallbackPath) {
    try {
      const response = await fetch(`http://127.0.0.1:8788${path}`, { headers: { Accept: 'application/json' } });
      if (response.ok) return { data: await response.json(), source: 'development-api' };
    } catch (error) { console.warn('Development API unavailable', error); }
    const fallback = await fetch(fallbackPath);
    return { data: await fallback.json(), source: 'local-demo-json' };
  }
  global.OnkofizjoApi = { get };
})(window);
