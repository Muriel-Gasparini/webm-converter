#!/bin/bash

# WebM Converter - Instalação Automática v1.0.0

set -euo pipefail

# Configurar locale para evitar problemas de encoding
export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=C 2>/dev/null || true

REPO_URL="https://github.com/Muriel-Gasparini/webm-converter"
RELEASE_VERSION="v1.0.0"
BINARY_URL="$REPO_URL/releases/download/$RELEASE_VERSION/webm-converter"
SERVICE_URL="$REPO_URL/raw/$RELEASE_VERSION/webm-converter.service"
INSTALL_SERVICE_URL="$REPO_URL/raw/$RELEASE_VERSION/install-service.sh"

BIN_DIR="$HOME/.local/bin"
SERVICE_DIR="/tmp/webm-converter-install"

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

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    print_error "Não execute como root! Execute como usuário normal."
    exit 1
fi

print_status "🚀 Iniciando instalação do WebM Converter $RELEASE_VERSION..."

# Verificar dependências
print_status "🔍 Verificando dependências..."

# Verificar curl ou wget
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    print_error "curl ou wget não encontrado!"
    print_status "Instale curl: sudo apt install curl"
    exit 1
fi

# Verificar/instalar FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    print_status "📦 FFmpeg não encontrado. Instalando via apt..."
    if sudo apt update && sudo apt install -y ffmpeg; then
        print_success "FFmpeg instalado com sucesso!"
    else
        print_error "Falha ao instalar FFmpeg!"
        exit 1
    fi
else
    print_success "FFmpeg já está instalado"
    ffmpeg -version | head -1
fi

# Criar diretórios
print_status "📁 Criando diretórios..."
mkdir -p "$BIN_DIR"
mkdir -p "$HOME/Videos/Screencasts"
mkdir -p "$SERVICE_DIR"

# Função para download
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
    else
        wget -q "$url" -O "$output"
    fi
}

# Baixar binário
print_status "📥 Baixando WebM Converter $RELEASE_VERSION..."
if ! download_file "$BINARY_URL" "$BIN_DIR/webm-converter"; then
    print_error "Falha ao baixar o executável!"
    print_error "Verifique se a release $RELEASE_VERSION existe em: $REPO_URL/releases"
    exit 1
fi

# Tornar executável
chmod +x "$BIN_DIR/webm-converter"

# Adicionar ao PATH se necessário
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_status "🔧 Adicionando ao PATH..."
    
    # Detectar shell e adicionar ao arquivo correto
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    # Verificar se a linha já existe no arquivo
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        print_success "PATH atualizado em $SHELL_RC"
        print_warning "Reinicie o terminal ou execute: source $SHELL_RC"
    fi
    
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verificar se está executando via pipe (stdin não é um terminal)
if [ -t 0 ]; then
    # Terminal interativo
    INTERACTIVE=true
else
    # Executando via pipe (curl | bash)
    INTERACTIVE=false
fi

# Instalar serviço systemd
if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Deseja instalar como serviço systemd? (y/N): " -n 1 -r
    echo ""
    INSTALL_SERVICE="$REPLY"
else
    # Modo não-interativo: instalar serviço por padrão
    print_status "Modo não-interativo detectado. Instalando serviço systemd..."
    INSTALL_SERVICE="y"
fi

if [[ $INSTALL_SERVICE =~ ^[Yy]$ ]]; then
    print_status "🔧 Baixando arquivos do serviço systemd..."
    
    # Baixar arquivos necessários para o serviço
    if download_file "$SERVICE_URL" "$SERVICE_DIR/webm-converter.service" && \
       download_file "$INSTALL_SERVICE_URL" "$SERVICE_DIR/install-service.sh"; then
        
        cd "$SERVICE_DIR" || exit 1
        chmod +x install-service.sh
        
        # Atualizar caminhos no serviço
        sed -i "s|ExecStart=.*|ExecStart=$BIN_DIR/webm-converter|g" webm-converter.service
        sed -i "s|WorkingDirectory=.*|WorkingDirectory=$HOME|g" webm-converter.service
        
        print_status "🔧 Instalando serviço systemd..."
        if sudo cp webm-converter.service /etc/systemd/system/ && \
           sudo systemctl daemon-reload && \
           sudo systemctl enable webm-converter && \
           sudo systemctl start webm-converter; then
            print_success "Serviço instalado e iniciado!"
        else
            print_warning "Falha ao instalar serviço. Continue com a instalação manual."
        fi
    else
        print_warning "Falha ao baixar arquivos do serviço."
    fi
fi

# Limpeza
rm -rf "$SERVICE_DIR"

# Verificação final
if [ -x "$BIN_DIR/webm-converter" ]; then
    print_success "✅ Instalação concluída com sucesso!"
    
    # Testar se o executável funciona
    print_status "🧪 Testando executável..."
    if "$BIN_DIR/webm-converter" --version 2>/dev/null || true; then
        print_success "Executável funcionando corretamente!"
    fi
else
    print_error "❌ Erro na instalação: executável não encontrado"
    exit 1
fi

printf "\n"
printf "📋 Como usar:\n"
printf "  🔴 Executar uma vez:     webm-converter\n"
printf "  🔴 Ver status serviço:   sudo systemctl status webm-converter\n"
printf "  🔴 Ver logs:             sudo journalctl -u webm-converter -f\n"
printf "  🔴 Parar serviço:        sudo systemctl stop webm-converter\n"
printf "  🔴 Iniciar serviço:      sudo systemctl start webm-converter\n"
printf "\n"
printf "📁 Pasta monitorada: %s\n" "$HOME/Videos/Screencasts"
printf "📦 Executável: %s\n" "$BIN_DIR/webm-converter"
printf "📦 Versão: %s\n" "$RELEASE_VERSION"
printf "\n"
printf "🎬 Agora grave sua tela com Gnome ScreenCast e os arquivos .webm\n"
printf "   serão automaticamente convertidos para .mp4!\n" 