/* Browser-only persistence adapter. Replace with authenticated API calls in production. */
(function (global) {
  const PREFIX = 'onkofizjo.demo.';
  const seed = { patient:'data/demo-patient.json', dietPlan:'data/demo-diet-plan.json', assistantRun:'data/demo-assistant-run.json', operations:'data/demo-operations.json' };
  async function read(key) { const stored=localStorage.getItem(PREFIX+key); if(stored) return JSON.parse(stored); const value=await (await fetch(seed[key])).json(); localStorage.setItem(PREFIX+key,JSON.stringify(value)); return value; }
  function write(key,value) { localStorage.setItem(PREFIX+key,JSON.stringify({...value,updatedAt:new Date().toISOString()})); return value; }
  function sessionRole() { return localStorage.getItem(PREFIX+'role') || 'gosia'; }
  function setSessionRole(role) { localStorage.setItem(PREFIX+'role',role); return role; }
  global.OnkofizjoStore={read,write,sessionRole,setSessionRole,prefix:PREFIX};
})(window);
