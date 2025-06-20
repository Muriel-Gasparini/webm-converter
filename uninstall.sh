#!/bin/bash

# WebM Converter - Desinstalação Completa
# ./uninstall.sh

set -e

INSTALL_DIR="$HOME/.local/webm-converter"
BIN_DIR="$HOME/.local/bin"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "🗑️  Iniciando desinstalação do WebM Converter..."

# Parar e remover serviço systemd
if systemctl is-active --quiet webm-converter 2>/dev/null; then
    print_status "⏹️  Parando serviço systemd..."
    sudo systemctl stop webm-converter
fi

if systemctl is-enabled --quiet webm-converter 2>/dev/null; then
    print_status "❌ Desabilitando serviço systemd..."
    sudo systemctl disable webm-converter
fi

if [ -f "/etc/systemd/system/webm-converter.service" ]; then
    print_status "🗑️  Removendo arquivo de serviço..."
    sudo rm -f /etc/systemd/system/webm-converter.service
    sudo systemctl daemon-reload
    sudo systemctl reset-failed 2>/dev/null || true
fi

# Remover executável
if [ -f "$BIN_DIR/webm-converter" ]; then
    print_status "🗑️  Removendo executável..."
    rm -f "$BIN_DIR/webm-converter"
fi

# Remover diretório de instalação
if [ -d "$INSTALL_DIR" ]; then
    print_status "🗑️  Removendo arquivos de instalação..."
    rm -rf "$INSTALL_DIR"
fi

# Limpar ffmpeg temporário
if [ -f "/tmp/webm-converter-ffmpeg" ]; then
    print_status "🧹 Limpando arquivos temporários..."
    rm -f /tmp/webm-converter-ffmpeg
fi

# Perguntar se deve remover pasta de vídeos
if [ -d "$HOME/Videos/Screencasts" ]; then
    echo ""
    read -p "Deseja remover a pasta $HOME/Videos/Screencasts? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "🗑️  Removendo pasta de vídeos..."
        rm -rf "$HOME/Videos/Screencasts"
    else
        print_warning "Pasta de vídeos mantida: $HOME/Videos/Screencasts"
    fi
fi

print_success "✅ Desinstalação concluída!"
echo ""
print_warning "📝 Nota: As entradas do PATH em ~/.bashrc, ~/.zshrc ou ~/.profile"
print_warning "   não foram removidas automaticamente. Se desejar, remova a linha:"
print_warning "   export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
print_success "🎬 WebM Converter foi completamente removido do sistema!" 