/**
 * Minimal server for Cloud Run: serves index.html with GEMINI_API_KEY injected from env.
 * API key comes from Cloud Run env (env.yaml).
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const INDEX_PATH = path.join(__dirname, 'index.html');

const server = http.createServer((req, res) => {
  const pathOnly = req.url?.split('?')[0] || '/';
  const hasQuery = (req.url?.includes('?'));

  if (pathOnly !== '/' && pathOnly !== '/index.html') {
    res.writeHead(404);
    res.end('Not Found');
    return;
  }

  // ถ้ามี query params (เช่น fbclid จาก Facebook) redirect ไป URL สะอาด
  if (hasQuery) {
    res.writeHead(302, { Location: pathOnly });
    res.end();
    return;
  }

  const apiKey = process.env.GEMINI_API_KEY || '';
  let html = fs.readFileSync(INDEX_PATH, 'utf8');
  html = html.replace(/__GEMINI_API_KEY__/g, apiKey);

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(html);
});

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
