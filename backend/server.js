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
app.use(bodyParser.json());

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
  const lower = brand.toLowerCase();

  if (lower.includes('everlane')) {
    return [
      { label: 'brand_website', text: 'Everlane publishes factory lists and cost breakdowns. Uses recycled polyester in some outerwear. Not all cotton is organic.' },
      { label: 'transparency_report_2023', text: 'Audited factories, profiles available online.' }
    ];
  }
  if (lower.includes('patagonia')) {
    return [
      { label: 'brand_website', text: 'Patagonia uses 87% recycled or regenerated materials. 100% organic cotton since 1996. Publishes Footprint Chronicles.' },
      { label: 'annual_report', text: '76% of products are Fair Trade Certified sewn. Carbon neutral across entire supply chain.' }
    ];
  }
  if (lower.includes('zara')) {
    return [
      { label: 'brand_website', text: 'Zara Join Life collection represents ~15% of production. Committed to net-zero by 2040.' },
      { label: 'industry_report', text: 'Produces billions of garments annually. Conventional cotton and synthetic fabrics dominate. Labor violations reported in supply chain.' }
    ];
  }
  if (lower.includes('h&m') || lower.includes('h and m')) {
    return [
      { label: 'brand_website', text: 'H&M Conscious Collection uses ~30% recycled or sustainably sourced materials. One of worlds largest organic cotton buyers.' },
      { label: 'sustainability_report', text: 'Largest fashion garment collector globally. Fair Living Wage strategy incomplete across all suppliers.' }
    ];
  }
  if (lower.includes('shein')) {
    return [
      { label: 'industry_report', text: 'Shein adds thousands of new items daily. Primarily cheap polyester. Minimal supply chain transparency.' },
      { label: 'investigation', text: 'Multiple investigations revealed concerning labor practices. No audited factory lists published.' }
    ];
  }
  if (lower.includes('nike')) {
    return [
      { label: 'brand_website', text: 'Nike Grind recycles manufacturing waste. Flyknit reduces waste by 60%. Move to Zero initiative targets zero carbon and zero waste.' },
      { label: 'sustainability_report', text: 'Comprehensive factory audit program. Reduced freshwater usage in dyeing by 30% since 2020.' }
    ];
  }
  if (lower.includes('reformation')) {
    return [
      { label: 'brand_website', text: 'Reformation uses deadstock and surplus fabrics. RefScale tracks CO2, water, and waste per garment. Carbon neutral since 2015.' },
      { label: 'factory_info', text: 'Majority manufactured in owned LA factory with fair wages. Strict supplier code of conduct.' }
    ];
  }
  if (lower.includes('uniqlo')) {
    return [
      { label: 'brand_website', text: 'Uniqlo RE.UNIQLO program recycles old garments. DRY-EX uses recycled PET bottles. LifeWear philosophy emphasizes durability.' },
      { label: 'industry_report', text: 'Publishes core factory list. Has faced scrutiny over cotton sourcing from sensitive regions.' }
    ];
  }

  // Generic fallback for unknown brands
  return [
    { label: 'brand_website', text: `${brand} has sustainability pages that mention some recycled materials but no audited factory lists or third-party certifications found in public sources.` }
  ];
}

// Local stub generator used for offline/dev fallback
function stubForBrand(brand, sources) {
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
    overall: { rating: "medium", score: null }
  };
}

// ---------- Helper: parse JSON from model output ----------
function tryParseJsonFromString(raw) {
  if (!raw || typeof raw !== 'string') return null;
  try { return JSON.parse(raw); } catch (e1) {}
  const match = raw.match(/\{[\s\S]*\}/m);
  if (match) {
    try { return JSON.parse(match[0]); } catch (e2) {}
  }
  return null;
}

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

// ---------- POST /api/brands/assess ----------
const USE_STUB = process.env.USE_STUB === 'true';

app.post('/api/brands/assess', async (req, res) => {
  console.log("POST /api/brands/assess called with body:", req.body);
  try {
    const brand = (req.body.brand || '').trim();
    if (!brand) return res.status(400).json({ error: "missing brand" });

    const sources = gatherSourcesForBrand(brand);

    if (USE_STUB) {
      console.log("USE_STUB=true -> returning local stub for", brand);
      return res.json(stubForBrand(brand, sources));
    }

    try {
      const llmResult = await callLLM(brand, sources);

      const ensurePillar = (p) => {
        if (!p) return { rating: "low", explanation: "", evidence: [] };
        p.evidence = Array.isArray(p.evidence) ? p.evidence : [];
        const r = (p.rating || "").toLowerCase();
        p.rating = ["low", "medium", "high"].includes(r) ? r : (p.evidence.length ? "medium" : "low");
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
        const numeric = Math.round((map[mats] + map[lab] * 1.2 + map[common]) / 3.2);
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
      console.warn("LLM call failed; falling back to stub. Error:", innerErr?.message || innerErr);
      console.log("Returning stub to keep dev flow smooth for", brand);
      return res.json(stubForBrand(brand, sources));
    }

  } catch (err) {
    console.error("ERROR in /api/brands/assess:", err?.message || err);
    res.status(500).json({ error: err.message || String(err) });
  }
});

// ---------- GET /api/brands/test — quick API key health check ----------
app.get('/api/brands/test', async (req, res) => {
  const GEMINI_KEY = process.env.GEMINI_API_KEY;
  if (!GEMINI_KEY) {
    return res.status(500).json({ ok: false, error: "GEMINI_API_KEY not set in .env" });
  }

  try {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent` +
      `?key=${GEMINI_KEY}`;

    const resp = await fetchFn(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: "Say hello in JSON: {\"greeting\":\"hello\"}" }] }],
        generationConfig: { temperature: 0.0, maxOutputTokens: 100 }
      })
    });

    if (!resp.ok) {
      const txt = await resp.text();
      return res.json({ ok: false, status: resp.status, error: txt });
    }

    const json = await resp.json();
    const raw = json?.candidates?.[0]?.content?.parts?.map(p => p.text).join("") || "";

    return res.json({ ok: true, gemini_response: raw.slice(0, 200) });
  } catch (err) {
    return res.json({ ok: false, error: err.message });
  }
});

// small root route to confirm server identity
app.get('/', (req, res) => res.send('GreenTag backend alive'));

app.listen(PORT, () => console.log(`Server listening on http://localhost:${PORT}`));
