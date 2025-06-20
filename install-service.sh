#!/bin/bash

# Script para instalar o WebM Converter como serviço systemd
# Execute com: sudo ./install-service.sh [usuario]

set -e

SERVICE_NAME="webm-converter"
SERVICE_FILE="webm-converter.service"
SYSTEMD_DIR="/etc/systemd/system"
CURRENT_DIR="$(pwd)"

echo "🚀 Instalando WebM Converter como serviço systemd..."

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script deve ser executado como root (use sudo)"
    exit 1
fi

# Detectar usuário atual (quem executou sudo)
if [ -n "$1" ]; then
    TARGET_USER="$1"
else
    TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
fi

# Detectar informações do usuário
TARGET_GROUP="$(id -gn $TARGET_USER 2>/dev/null || echo $TARGET_USER)"
HOME_DIR="$(eval echo ~$TARGET_USER)"
WORKING_DIR="$CURRENT_DIR"
EXEC_PATH="$CURRENT_DIR/dist/webm-converter-linux"
WATCH_DIR="$HOME_DIR/Videos/Screencasts"

echo "📋 Configurações detectadas:"
echo "  Usuário: $TARGET_USER"
echo "  Grupo: $TARGET_GROUP"
echo "  Home: $HOME_DIR"
echo "  Diretório de trabalho: $WORKING_DIR"
echo "  Executável: $EXEC_PATH"
echo "  Pasta monitorada: $WATCH_DIR"
echo ""

# Verificar se o executável existe
if [ ! -f "dist/webm-converter-linux" ]; then
    echo "❌ Executável não encontrado em dist/webm-converter-linux"
    echo "Execute 'yarn build:linux' primeiro"
    exit 1
fi

# Verificar se o ícone existe
if [ ! -f "dist/icon.png" ]; then
    echo "⚠️ Ícone não encontrado em dist/icon.png"
    echo "Execute 'yarn build:linux' primeiro para incluir o ícone"
fi

# Verificar se o arquivo de serviço existe
if [ ! -f "$SERVICE_FILE" ]; then
    echo "❌ Arquivo de serviço não encontrado: $SERVICE_FILE"
    exit 1
fi

# Criar pasta de vídeos se não existir
echo "📁 Verificando/criando pasta de vídeos..."
if [ ! -d "$WATCH_DIR" ]; then
    sudo -u "$TARGET_USER" mkdir -p "$WATCH_DIR"
    echo "✅ Pasta criada: $WATCH_DIR"
else
    echo "✅ Pasta já existe: $WATCH_DIR"
fi

# Copiar ícone para local compartilhado se existir
SHARE_DIR="$HOME_DIR/.local/share/webm-converter"
if [ -f "dist/icon.png" ]; then
    echo "🖼️ Copiando ícone para $SHARE_DIR..."
    sudo -u "$TARGET_USER" mkdir -p "$SHARE_DIR"
    sudo -u "$TARGET_USER" cp "dist/icon.png" "$SHARE_DIR/"
    echo "✅ Ícone copiado para $SHARE_DIR/icon.png"
fi

# Parar o serviço se estiver rodando
echo "⏹️  Parando serviço se estiver rodando..."
systemctl stop $SERVICE_NAME 2>/dev/null || true

# Gerar arquivo de serviço personalizado
echo "🔧 Gerando arquivo de serviço personalizado..."
sed -e "s|{{USER}}|$TARGET_USER|g" \
    -e "s|{{GROUP}}|$TARGET_GROUP|g" \
    -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
    -e "s|{{WORKING_DIR}}|$WORKING_DIR|g" \
    -e "s|{{EXEC_PATH}}|$EXEC_PATH|g" \
    -e "s|{{WATCH_DIR}}|$WATCH_DIR|g" \
    "$SERVICE_FILE" > "$SYSTEMD_DIR/$SERVICE_FILE"

echo "✅ Arquivo de serviço gerado em $SYSTEMD_DIR/$SERVICE_FILE"

# Recarregar systemd
echo "🔄 Recarregando systemd daemon..."
systemctl daemon-reload

# Habilitar serviço para iniciar automaticamente
echo "✅ Habilitando serviço para iniciar automaticamente..."
systemctl enable $SERVICE_NAME

# Iniciar serviço
echo "🚀 Iniciando serviço..."
systemctl start $SERVICE_NAME

# Verificar status
echo "📊 Status do serviço:"
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "✅ Instalação concluída!"
echo ""
echo "📋 Comandos úteis:"
echo "  Verificar status:    sudo systemctl status $SERVICE_NAME"
echo "  Iniciar serviço:     sudo systemctl start $SERVICE_NAME"
echo "  Parar serviço:       sudo systemctl stop $SERVICE_NAME"
echo "  Reiniciar serviço:   sudo systemctl restart $SERVICE_NAME"
echo "  Ver logs:            sudo journalctl -u $SERVICE_NAME -f"
echo "  Desabilitar:         sudo systemctl disable $SERVICE_NAME"
echo ""
echo "🔍 Para ver os logs em tempo real:"
echo "  sudo journalctl -u $SERVICE_NAME -f" 