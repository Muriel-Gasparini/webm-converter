#!/bin/bash

# WebM Converter - Instalação Automática

set -e

REPO_URL="https://github.com/Muriel-Gasparini/webm-converter.git"
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

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    print_error "Não execute como root! Execute como usuário normal."
    exit 1
fi

print_status "🚀 Iniciando instalação do WebM Converter..."

# Verificar dependências
print_status "🔍 Verificando dependências..."

# Verificar Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js não encontrado!"
    print_status "Instale Node.js primeiro:"
    print_status "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    print_status "sudo apt-get install -y nodejs"
    exit 1
fi

# Verificar Yarn
if ! command -v yarn &> /dev/null; then
    print_status "📦 Instalando Yarn..."
    npm install -g yarn
fi

# Verificar Git
if ! command -v git &> /dev/null; then
    print_error "Git não encontrado!"
    print_status "Instale git: sudo apt install git"
    exit 1
fi

# Criar diretórios
print_status "📁 Criando diretórios..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$HOME/Videos/Screencasts"

# Clonar repositório
print_status "📥 Baixando WebM Converter..."
if [ -d "$INSTALL_DIR/.git" ]; then
    print_status "Atualizando repositório existente..."
    cd "$INSTALL_DIR"
    git pull
else
    print_status "Clonando repositório..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Instalar dependências
print_status "📦 Instalando dependências..."
yarn install

# Gerar build
print_status "🔨 Compilando executável..."
yarn build:linux

# Copiar executável para bin
print_status "📋 Instalando executável..."
cp dist/webm-converter-linux "$BIN_DIR/webm-converter"
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
    
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    export PATH="$HOME/.local/bin:$PATH"
    
    print_success "PATH atualizado em $SHELL_RC"
    print_warning "Reinicie o terminal ou execute: source $SHELL_RC"
fi

# Instalar serviço systemd
read -p "Deseja instalar como serviço systemd? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "🔧 Instalando serviço systemd..."
    
    # Atualizar caminhos no script de instalação do serviço
    sed -i "s|WORKING_DIR=\"\$CURRENT_DIR\"|WORKING_DIR=\"$INSTALL_DIR\"|g" install-service.sh
    sed -i "s|EXEC_PATH=\"\$CURRENT_DIR/dist/webm-converter-linux\"|EXEC_PATH=\"$BIN_DIR/webm-converter\"|g" install-service.sh
    
    sudo ./install-service.sh
    print_success "Serviço instalado e iniciado!"
fi

# Limpeza opcional
read -p "Deseja manter os arquivos de desenvolvimento? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "🧹 Limpando arquivos desnecessários..."
    cd "$INSTALL_DIR"
    rm -rf node_modules .git yarn.lock
    find . -name "*.js" -not -path "./dist/*" -delete
    find . -name "*.json" -not -path "./dist/*" -delete
    print_success "Limpeza concluída!"
fi

print_success "✅ Instalação concluída!"
echo ""
echo "📋 Como usar:"
echo "  🔴 Executar uma vez:     webm-converter"
echo "  🔴 Ver status serviço:   sudo systemctl status webm-converter"
echo "  🔴 Ver logs:             sudo journalctl -u webm-converter -f"
echo "  🔴 Parar serviço:        sudo systemctl stop webm-converter"
echo "  🔴 Iniciar serviço:      sudo systemctl start webm-converter"
echo ""
echo "📁 Pasta monitorada: $HOME/Videos/Screencasts"
echo "📦 Executável: $BIN_DIR/webm-converter"
echo "⚙️  Código fonte: $INSTALL_DIR"
echo ""
echo "🎬 Agora grave sua tela com Gnome ScreenCast e os arquivos .webm"
echo "   serão automaticamente convertidos para .mp4!" 