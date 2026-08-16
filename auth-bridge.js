/* Development-only auth bridge. Production must use an HttpOnly session cookie. */
(function () {
  const originalFetch = window.fetch.bind(window);
  let tokenPromise;
  function token() {
    const stored = sessionStorage.getItem('onkofizjo.demo.accessToken');
    if (stored) return Promise.resolve(stored);
    if (!tokenPromise) tokenPromise = originalFetch('http://127.0.0.1:8797/api/auth/session', { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify({ userId: 'demo-gosia', role: 'GOSIA' }) }).then(response => { if (!response.ok) throw new Error('Authentication required'); return response.json(); }).then(session => { sessionStorage.setItem('onkofizjo.demo.accessToken', session.accessToken); return session.accessToken; });
    return tokenPromise;
  }
  window.fetch = async function (input, init = {}) {
    const url = typeof input === 'string' ? input : input.url;
    const method = (init.method || (typeof input !== 'string' ? input.method : 'GET')).toUpperCase();
    if (!url.includes('/api/') || url.endsWith('/api/auth/session') || url.endsWith('/api/health')) return originalFetch(input, init);
    const headers = new Headers(init.headers || (typeof input !== 'string' ? input.headers : undefined));
    if (!headers.has('Authorization')) headers.set('Authorization', `Bearer ${await token()}`);
    return originalFetch(input, { ...init, headers });
  };
})();
