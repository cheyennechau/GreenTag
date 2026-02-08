// server.js (overwrite your existing file with this)
require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');

// try to use global fetch (Node 18+), otherwise try node-fetch
let fetchFn = global.fetch;
if (!fetchFn) {
  try {
    fetchFn = require('node-fetch');
  } catch (e) {
    console.error("No fetch available. Install node-fetch or run Node 18+.");
    process.exit(1);
  }
}

const app = express();
app.use(bodyParser.json()); // <-- must come before routes

const PORT = process.env.PORT || 3000;

// ---------------- PROMPT TEMPLATES ----------------

const SYSTEM_PROMPT = `
You are a JSON-only generator.
You must respond with strictly valid JSON.
Do not include explanations, markdown, or commentary.
`;

function buildUserPrompt(brand, sourcesText) {
  return `
Brand: ${brand}

Available sources:
${sourcesText}

Task:
Using ONLY the sources above, return a JSON object with this exact schema:

{
  "brand": "<string>",
  "summary": "<short paragraph>",
  "pillars": {
    "materials": {
      "rating": "low|medium|high",
      "explanation": "<string>",
      "evidence": [{"source":"SOURCE_n","text":"<snippet>"}]
    },
    "labor": {
      "rating": "low|medium|high",
      "explanation": "<string>",
      "evidence": [{"source":"SOURCE_n","text":"<snippet>"}]
    },
    "materials_common": {
      "rating": "low|medium|high",
      "explanation": "<string>",
      "evidence": [{"source":"SOURCE_n","text":"<snippet>"}]
    }
  },
  "overall": {
    "rating": "low|medium|high",
    "score": null
  }
}

Rules:
- Ratings must be based on evidence strength.
- Use HIGH only with audited factories or certifications.
- Use MEDIUM for partial transparency.
- Use LOW when evidence is missing.
- Output JSON ONLY.
`;
}

const FEW_SHOT_EXAMPLE = `
Example:

Brand: Patagonia
Available sources:
SOURCE_1 [patagonia_site]: "Publishes Footprint Chronicles and uses 70% recycled materials."
SOURCE_2 [patagonia_report]: "Annual report confirms audited factories."

OUTPUT:
{
  "brand": "Patagonia",
  "summary": "Patagonia is a leader in transparency with high recycled material use and audited factories.",
  "pillars": {
    "materials": {
      "rating": "high",
      "explanation": "High recycled material usage documented.",
      "evidence": [{"source":"SOURCE_1","text":"Uses 70% recycled materials"}]
    },
    "labor": {
      "rating": "high",
      "explanation": "Audited factories published.",
      "evidence": [{"source":"SOURCE_2","text":"Annual report confirms audited factories"}]
    },
    "materials_common": {
      "rating": "high",
      "explanation": "Common materials are recycled polyester and organic cotton.",
      "evidence": []
    }
  },
  "overall": {"rating":"high","score":85}
}
`;

// ---------- Mock source gatherer (replace with real scrapers later) ----------
function gatherSourcesForBrand(brand) {
  if (!brand) return [];
  if (brand.toLowerCase().includes('everlane')) {
    return [
      { label: 'brand_website', text: 'Everlane publishes factory lists and cost breakdowns. Uses recycled polyester in some outerwear. Not all cotton is organic.' },
      { label: 'transparency_report_2023', text: 'Audited factories, profiles available online.' }
    ];
  }
  return [
    { label: 'brand_website', text: `${brand} has sustainability pages that mention some recycled materials but no audited factory lists.` }
  ];
}

// Local stub generator used for offline/dev fallback
function stubForBrand(brand, sources) {
  // You can make this fancier — vary by brand or use sample fixtures.
  const sourceSnippet = (sources && sources[0] && sources[0].text) ? sources[0].text : "";
  return {
    brand,
    summary: `${brand} (local stub): partial transparency detected. This is offline demo data.`,
    pillars: {
      materials: {
        rating: "medium",
        explanation: "Some recycled materials mentioned; limited structured material certification evidence in public sources.",
        evidence: sourceSnippet ? [{ source: "SOURCE_1", text: sourceSnippet }] : []
      },
      labor: {
        rating: "medium",
        explanation: "Some factory locations or partner mentions; independent audits not clearly available in the public snippets.",
        evidence: sourceSnippet ? [{ source: "SOURCE_1", text: sourceSnippet }] : []
      },
      materials_common: {
        rating: "medium",
        explanation: "Common materials include cotton and polyester; limited use of organic/recycled at scale.",
        evidence: []
      }
    },
    overall: { rating: "medium", score: 60 }
  };
}

// ---------- Helper: parse JSON from model output ----------
function tryParseJsonFromString(raw) {
  if (!raw || typeof raw !== 'string') return null;
  // try direct parse
  try { return JSON.parse(raw); } catch (e1) {}
  // try to extract the first {...} block
  const match = raw.match(/\{[\s\S]*\}/m);
  if (match) {
    try { return JSON.parse(match[0]); } catch (e2) {}
  }
  return null;
}

// ---------- callLLM using REST fetch ----------
//async function callLLM(brand, sources) {
//  const OPENAI_KEY = process.env.OPENAI_API_KEY;
//  if (!OPENAI_KEY) throw new Error("Missing OPENAI_API_KEY in environment.");
//
//  const sourcesText = sources.map((s, i) => `SOURCE_${i+1} [${s.label}]: ${s.text}`).join("\n");
//  const userPrompt = buildUserPrompt(brand, sourcesText) + "\n\n" + FEW_SHOT_EXAMPLE;
//
//  const messages = [
//    { role: "system", content: SYSTEM_PROMPT },
//    { role: "user", content: userPrompt }
//  ];
//
//  const body = {
//    model: "gpt-4o-mini", // change if you don't have access
//    messages,
//    temperature: 0.0,
//    max_tokens: 1200
//  };
//
//  const resp = await fetchFn("https://api.openai.com/v1/chat/completions", {
//    method: "POST",
//    headers: {
//      "Content-Type": "application/json",
//      "Authorization": `Bearer ${OPENAI_KEY}`
//    },
//    body: JSON.stringify(body)
//  });
//
//  if (!resp.ok) {
//    const txt = await resp.text();
//    throw new Error(`OpenAI API error ${resp.status}: ${txt}`);
//  }
//
//  const json = await resp.json();
//  const raw = json?.choices?.[0]?.message?.content ?? json?.choices?.[0]?.text ?? "";
//  // debug logging (safe): limit length
//  console.log("RAW MODEL OUTPUT (trimmed):", raw?.slice ? raw.slice(0, 1000) : raw);
//
//  const parsed = tryParseJsonFromString(raw);
//  if (!parsed) throw new Error("Model did not return parseable JSON. Raw snippet: " + (raw?.slice ? raw.slice(0,800) : raw));
//  return parsed;
//}
// ---------- callLLM using Gemini REST API ----------
async function callLLM(brand, sources) {
  const GEMINI_KEY = process.env.GEMINI_API_KEY;
  if (!GEMINI_KEY) {
    throw new Error("Missing GEMINI_API_KEY in environment.");
  }

  const sourcesText = sources
    .map((s, i) => `SOURCE_${i + 1} [${s.label}]: ${s.text}`)
    .join("\n");

  const userPrompt =
    buildUserPrompt(brand, sourcesText) + "\n\n" + FEW_SHOT_EXAMPLE;

  const body = {
    contents: [
      { parts: [{ text: SYSTEM_PROMPT }] },
      { parts: [{ text: userPrompt }] }
    ],
    generationConfig: {
      temperature: 0.0,
      maxOutputTokens: 1200
    }
  };

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent` +
    `?key=${GEMINI_KEY}`;

  const resp = await fetchFn(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });

  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`Gemini API error ${resp.status}: ${txt}`);
  }

  const json = await resp.json();

  // Gemini returns text inside candidates[0].content.parts[]
  const raw =
    json?.candidates?.[0]?.content?.parts
      ?.map(p => p.text)
      .join("") || "";

  console.log("RAW GEMINI OUTPUT (trimmed):", raw.slice(0, 800));

  const parsed = tryParseJsonFromString(raw);
  if (!parsed) {
    throw new Error("Gemini did not return parseable JSON.");
  }

  return parsed;
}

// ---------- POST /api/brands/assess (with USE_STUB and quota fallback) ----------
const USE_STUB = process.env.USE_STUB === 'true';

app.post('/api/brands/assess', async (req, res) => {
  console.log("POST /api/brands/assess called with body:", req.body);
  try {
    const brand = (req.body.brand || '').trim();
    if (!brand) return res.status(400).json({ error: "missing brand" });

    const sources = gatherSourcesForBrand(brand);

    // If developer wants to force stub mode, return the stub immediately
    if (USE_STUB) {
      console.log("USE_STUB=true -> returning local stub for", brand);
      return res.json(stubForBrand(brand, sources));
    }

    // Try Gemini (or any LLM). If it fails due to quota/billing/network, fallback to stub.
    try {
      const llmResult = await callLLM(brand, sources);

      // Basic normalization (same as before)
      const ensurePillar = (p) => {
        if (!p) return { rating: "low", explanation: "", evidence: [] };
        p.evidence = Array.isArray(p.evidence) ? p.evidence : [];
        const r = (p.rating || "").toLowerCase();
        p.rating = ["low","medium","high"].includes(r) ? r : (p.evidence.length ? "medium" : "low");
        return p;
      };

      const materials = ensurePillar(llmResult.pillars?.materials);
      const labor = ensurePillar(llmResult.pillars?.labor);
      const materials_common = ensurePillar(llmResult.pillars?.materials_common);

      if (!llmResult.overall || !llmResult.overall.rating) {
        const map = { low: 30, medium: 60, high: 85 };
        const mats = materials.rating || "low";
        const lab = labor.rating || "low";
        const common = materials_common.rating || "low";
        const numeric = Math.round((map[mats] + map[lab]*1.2 + map[common]) / 3.2);
        const overallRating = numeric >= 70 ? "high" : (numeric >= 40 ? "medium" : "low");
        llmResult.overall = { rating: overallRating, score: numeric };
      }

      const out = {
        brand: llmResult.brand || brand,
        summary: llmResult.summary || "",
        pillars: { materials, labor, materials_common },
        overall: llmResult.overall
      };

      return res.json(out);

    } catch (innerErr) {
      // Log the LLM error for debugging
      console.warn("LLM call failed; falling back to stub. Error:", innerErr && innerErr.message ? innerErr.message : innerErr);

      // If it's a quota/billing/rate-limit-related error, we'll return stub
      const msg = (innerErr && innerErr.message) ? innerErr.message.toLowerCase() : "";

      if (msg.includes("quota") || msg.includes("429") || msg.includes("rate-limit") || msg.includes("quota exceeded") || msg.includes("insufficient")) {
        console.log("Detected quota/rate-limit error; returning local stub for", brand);
        return res.json(stubForBrand(brand, sources));
      }

      // For other kinds of LLM errors, still fall back to stub to keep the UX working.
      console.log("Non-quota LLM error — returning stub to keep dev flow smooth.");
      return res.json(stubForBrand(brand, sources));
    }

  } catch (err) {
    console.error("ERROR in /api/brands/assess:", err && err.message ? err.message : err);
    res.status(500).json({ error: err.message || String(err) });
  }
});

// small root route to confirm server identity
app.get('/', (req, res) => res.send('GreenTag backend alive'));

app.listen(PORT, () => console.log(`Server listening on http://localhost:${PORT}`));
