//
//  server.js
//  OneWord Cloud Hub (Node.js Lightweight Server)
//

const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const PORT = process.env.PORT || 8765;
const DATA_DIR = path.join(__dirname, "data");
const ARTICLES_FILE = path.join(DATA_DIR, "articles.json");
const PUBLIC_DIR = path.join(__dirname, "public");

// Garante que o diretório de dados existe
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Inicializa arquivo de artigos se não existir
if (!fs.existsSync(ARTICLES_FILE)) {
  const initialArticles = [
    {
      id: "demo-1",
      title: "Bem-vindo ao OneWord Cloud",
      text: "O OneWord Cloud armazena seus artigos capturados pelo Google Chrome e permite leitura em velocidade do pensamento através da técnica RSVP e guias foveais ORP em qualquer dispositivo.",
      words: 27,
      url: "https://oneword.app",
      createdAt: new Date().toISOString()
    }
  ];
  fs.writeFileSync(ARTICLES_FILE, JSON.stringify(initialArticles, null, 2), "utf8");
}

function loadArticles() {
  try {
    const raw = fs.readFileSync(ARTICLES_FILE, "utf8");
    return JSON.parse(raw);
  } catch (err) {
    console.error("Erro ao ler articles.json:", err);
    return [];
  }
}

function saveArticles(articles) {
  try {
    fs.writeFileSync(ARTICLES_FILE, JSON.stringify(articles, null, 2), "utf8");
  } catch (err) {
    console.error("Erro ao salvar articles.json:", err);
  }
}

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon"
};

const server = http.createServer((req, res) => {
  // CORS Headers universais
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;

  // Health check
  if (req.method === "GET" && (pathname === "/health" || pathname === "/status")) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      status: "ok",
      app: "OneWord Cloud",
      version: "1.0.0",
      timestamp: new Date().toISOString()
    }));
    return;
  }

  // API: Receber artigo do Chrome ou do App
  if (req.method === "POST" && (pathname === "/read" || pathname === "/api/articles")) {
    let body = "";
    req.on("data", chunk => {
      body += chunk;
      // Limite de segurança de 10MB
      if (body.length > 10 * 1024 * 1024) {
        req.destroy();
      }
    });

    req.on("end", () => {
      try {
        const payload = JSON.parse(body);
        const text = (payload.text || "").trim();
        const title = (payload.title || "Artigo Capturado").trim();
        const sourceUrl = (payload.url || "").trim();

        if (!text) {
          res.writeHead(422, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "Texto vazio" }));
          return;
        }

        const words = text.split(/\s+/).filter(w => w.length > 0);
        const article = {
          id: crypto.randomUUID(),
          title: title,
          text: text,
          words: words.length,
          url: sourceUrl,
          createdAt: new Date().toISOString()
        };

        const articles = loadArticles();
        articles.unshift(article); // Adiciona no início da fila
        // Mantém até 200 artigos recentes
        if (articles.length > 200) {
          articles.pop();
        }
        saveArticles(articles);

        console.log(`[OneWord Cloud] Novo artigo salvo: "${title}" (${words.length} palavras)`);

        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({
          success: true,
          article: article
        }));
      } catch (err) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "JSON inválido: " + err.message }));
      }
    });
    return;
  }

  // API: Listar artigos
  if (req.method === "GET" && pathname === "/api/articles") {
    const articles = loadArticles();
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(articles));
    return;
  }

  // API: Deletar artigo
  if (req.method === "DELETE" && pathname.startsWith("/api/articles/")) {
    const id = pathname.replace("/api/articles/", "").trim();
    let articles = loadArticles();
    const initialCount = articles.length;
    articles = articles.filter(a => a.id !== id);
    saveArticles(articles);

    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      success: true,
      deleted: articles.length < initialCount
    }));
    return;
  }

  // Servir arquivos estáticos do Web RSVP Reader
  let filePath = path.join(PUBLIC_DIR, pathname === "/" ? "index.html" : pathname);

  // Prevenção de Path Traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // Fallback para index.html para SPA se não for encontrado
      const indexPath = path.join(PUBLIC_DIR, "index.html");
      fs.readFile(indexPath, (readErr, content) => {
        if (readErr) {
          res.writeHead(404, { "Content-Type": "text/plain" });
          res.end("404 Not Found");
        } else {
          res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
          res.end(content);
        }
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || "application/octet-stream";

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(500);
        res.end("Server Error");
      } else {
        res.writeHead(200, { "Content-Type": contentType });
        res.end(content);
      }
    });
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`🌐 OneWord Cloud Hub em execução na porta ${PORT}`);
  console.log(`🔗 Endpoint de recebimento: http://0.0.0.0:${PORT}/read`);
});
