#!/bin/bash

# Script para desinstalar o serviço WebM Converter
# Execute com: sudo ./uninstall-service.sh

set -e

SERVICE_NAME="webm-converter"
SERVICE_FILE="webm-converter.service"
SYSTEMD_DIR="/etc/systemd/system"

echo "🗑️  Desinstalando serviço WebM Converter..."

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script deve ser executado como root (use sudo)"
    exit 1
fi

# Parar serviço
echo "⏹️  Parando serviço..."
systemctl stop $SERVICE_NAME 2>/dev/null || true

# Desabilitar serviço
echo "❌ Desabilitando serviço..."
systemctl disable $SERVICE_NAME 2>/dev/null || true

# Remover arquivo de serviço
echo "🗑️  Removendo arquivo de serviço..."
rm -f "$SYSTEMD_DIR/$SERVICE_FILE"

# Recarregar systemd
echo "🔄 Recarregando systemd daemon..."
systemctl daemon-reload

# Reset de possíveis falhas
systemctl reset-failed 2>/dev/null || true

echo ""
echo "✅ Serviço desinstalado com sucesso!"
echo ""
echo "O executável ainda está disponível em dist/webm-converter-linux"
echo "Para executar manualmente: ./dist/webm-converter-linux" 