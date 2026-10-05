#!/bin/bash
# Script para iniciar o OneWord nativo no macOS com servidor de integração do Chrome
cd "$(dirname "$0")/.."

echo "🚀 Iniciando OneWord App no macOS..."
swift build -c release --product OneWordApp
if [ $? -eq 0 ]; then
    echo "✅ OneWord pronto! Conexão Chrome ativa na porta 8765."
    .build/out/Products/Release/OneWordApp
else
    echo "⚠️ Erro ao compilar. Tentando versão debug..."
    .build/out/Products/Debug/OneWordApp
fi
