#!/bin/bash
# Saleor Dashboard — script de inicialização standalone
# Pode ser executado de qualquer lugar, basta ter Node.js >= 22 e pnpm instalados

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/dashboard"
PORT="${PORT:-9000}"
API_URL="${API_URL:-http://localhost:8000/graphql/}"

echo "=== Saleor Dashboard ==="
echo "API URL: $API_URL"
echo "Porta: $PORT"

# Se o build não existir, compila primeiro
if [ ! -f "$BUILD_DIR/index.html" ]; then
  echo "Build não encontrado. Compilando..."
  cd "$SCRIPT_DIR"
  CI=true pnpm install --config.engine-strict=false
  API_URL="$API_URL" CI=true pnpm build
fi

# Serve os arquivos estáticos
node - <<EOF
const http = require('http');
const fs = require('fs');
const path = require('path');

const BUILD_DIR = '$BUILD_DIR';
const PORT = $PORT;

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.ttf': 'font/ttf',
};

const server = http.createServer((req, res) => {
  let filePath = path.join(BUILD_DIR, req.url === '/' ? '/index.html' : req.url);
  if (!fs.existsSync(filePath)) filePath = path.join(BUILD_DIR, 'index.html');
  const ext = path.extname(filePath);
  res.setHeader('Content-Type', MIME[ext] || 'application/octet-stream');
  res.setHeader('Access-Control-Allow-Origin', '*');
  fs.createReadStream(filePath).on('error', () => {
    res.writeHead(404);
    res.end('Not found');
  }).pipe(res);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('Dashboard disponivel em: http://localhost:' + PORT + '/');
  console.log('Conectado a API: $API_URL');
  console.log('Login: admin@example.com / admin');
});
EOF
