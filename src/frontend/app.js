const express = require("express");
const app = express();
const PORT = 3000;
const BACKEND_URL = process.env.BACKEND_URL || "http://backend-service:8000";

app.get("/", async (_req, res) => {
  try {
    const resp = await fetch(`${BACKEND_URL}/api/data`);
    const data = await resp.json();
    res.json({ source: "frontend", backend_says: data });
  } catch (err) {
    res.status(502).json({ error: "Backend unreachable", detail: err.message });
  }
});

app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.listen(PORT, () => console.log(`Frontend listening on :${PORT}`));
