// ─────────────────────────────────────────────────────────────────
// Generic Salesforce REST Proxy — Cloudflare Worker
// Change SF_URL and JWT_SECRET per project. Nothing else.
// Three jobs:
//   1. CORS preflight
//   2. GetToken — signs a JWT from whatever the app sends
//   3. Everything else — verify JWT, forward to Salesforce
// ─────────────────────────────────────────────────────────────────

const SF_URL     = "https://empathetic-raccoon-47lfd3-dev-ed.trailblaze.my.salesforce-sites.com/holidayquest/services/apexrest/restAPIPostEndpoint";
const JWT_SECRET = "change-this-before-going-live";
const JWT_HOURS  = 12;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age":       "86400",
};

function jsonResp(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

async function signJWT(payload) {
  const h    = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const b    = btoa(JSON.stringify({ ...payload, exp: Math.floor(Date.now() / 1000) + JWT_HOURS * 3600 }));
  const data = `${h}.${b}`;
  const key  = await crypto.subtle.importKey("raw", new TextEncoder().encode(JWT_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig  = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data));
  return `${data}.${btoa(String.fromCharCode(...new Uint8Array(sig)))}`;
}

async function verifyJWT(token) {
  try {
    const [h, b, sig] = token.split(".");
    if (!h || !b || !sig) return null;
    const key   = await crypto.subtle.importKey("raw", new TextEncoder().encode(JWT_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
    const valid = await crypto.subtle.verify("HMAC", key, Uint8Array.from(atob(sig), c => c.charCodeAt(0)), new TextEncoder().encode(`${h}.${b}`));
    if (!valid) return null;
    const p = JSON.parse(atob(b));
    if (p.exp < Math.floor(Date.now() / 1000)) return null;
    return p;
  } catch { return null; }
}

async function callSF(body) {
  const res  = await fetch(SF_URL, { method: "POST", headers: { "Content-Type": "text/plain" }, body });
  const text = await res.text();
  return { status: res.status, text };
}

export default {
  async fetch(request) {

    // 1. CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 200, headers: CORS_HEADERS });
    }

    if (request.method !== "POST") {
      return jsonResp({ error: "Method not allowed" }, 405);
    }

    const rawBody = await request.text();
    let parsed;
    try { parsed = JSON.parse(rawBody); }
    catch { return jsonResp({ error: "Invalid JSON" }, 400); }

    // Public routes — no JWT needed
    const publicRoutes = ["GetToken", "CreateClient", "VerifyClient", "SetupAccount", "CheckEmail"];
    if (publicRoutes.includes(parsed.type)) {
      if (parsed.type === "GetToken") {
        if (!parsed.payload?.sub) return jsonResp({ error: "Missing sub in payload" }, 400);
        const token = await signJWT(parsed.payload);
        return jsonResp({ token });
      }
      // All other public routes — forward straight to Salesforce
      const sf = await callSF(rawBody);
      try {
        return jsonResp(JSON.parse(sf.text), sf.status);
      } catch {
        return new Response(sf.text, { status: sf.status, headers: { ...CORS_HEADERS, "Content-Type": "text/plain" } });
      }
    }

    // 3. All other requests — JWT required, forward to Salesforce
    const auth  = request.headers.get("Authorization") || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : null;
    if (!token) return jsonResp({ error: "No token" }, 401);

    const jwt = await verifyJWT(token);
    if (!jwt)  return jsonResp({ error: "Invalid or expired token" }, 401);

    const sf = await callSF(rawBody);
    try {
      return jsonResp(JSON.parse(sf.text), sf.status);
    } catch {
      return new Response(sf.text, { status: sf.status, headers: { ...CORS_HEADERS, "Content-Type": "text/plain" } });
    }
  }
};