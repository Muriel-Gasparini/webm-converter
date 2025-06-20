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

# Verificar versão do Node.js
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    print_error "Node.js versão $NODE_VERSION encontrada. Necessária versão 16 ou superior."
    exit 1
fi

# Verificar npm
if ! command -v npm &> /dev/null; then
    print_error "npm não encontrado! Instale Node.js com npm."
    exit 1
fi

# Verificar Yarn
if ! command -v yarn &> /dev/null; then
    print_status "📦 Instalando Yarn..."
    if ! npm install -g yarn; then
        print_error "Falha ao instalar Yarn. Tente executar com sudo se necessário."
        exit 1
    fi
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

# Remover instalação anterior se existir
if [ -d "$INSTALL_DIR" ] && [ "$(ls -A "$INSTALL_DIR")" ]; then
    print_status "🧹 Removendo instalação anterior..."
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Clonar repositório
print_status "📥 Baixando WebM Converter..."
if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
    print_error "Falha ao clonar repositório!"
    exit 1
fi

cd "$INSTALL_DIR" || {
    print_error "Falha ao acessar diretório de instalação!"
    exit 1
}

# Instalar dependências
print_status "📦 Instalando dependências..."
if ! yarn install; then
    print_error "Falha ao instalar dependências!"
    exit 1
fi

# Verificar se pkg está disponível globalmente, senão instalar
if ! command -v pkg &> /dev/null; then
    print_status "📦 Instalando pkg globalmente..."
    if ! npm install -g pkg; then
        print_error "Falha ao instalar pkg. Tente executar com sudo se necessário."
        exit 1
    fi
fi

# Copiar ffmpeg para pasta bin local
print_status "📦 Copiando ffmpeg..."
mkdir -p bin
if [ -f "node_modules/@ffmpeg-installer/linux-x64/ffmpeg" ]; then
    cp node_modules/@ffmpeg-installer/linux-x64/ffmpeg bin/ffmpeg
    chmod +x bin/ffmpeg
else
    print_error "FFmpeg não encontrado em node_modules!"
    exit 1
fi

# Gerar build
print_status "🔨 Compilando executável..."
if ! yarn build:linux; then
    print_error "Falha ao compilar executável!"
    exit 1
fi

# Verificar se o executável foi gerado
if [ ! -f "dist/webm-converter-linux" ]; then
    print_error "Executável não foi gerado!"
    exit 1
fi

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
    if [ -f "install-service.sh" ]; then
        print_status "🔧 Instalando serviço systemd..."
        
        # Atualizar caminhos no script de instalação do serviço
        sed -i "s|WORKING_DIR=\"\$CURRENT_DIR\"|WORKING_DIR=\"$INSTALL_DIR\"|g" install-service.sh
        sed -i "s|EXEC_PATH=\"\$CURRENT_DIR/dist/webm-converter-linux\"|EXEC_PATH=\"$BIN_DIR/webm-converter\"|g" install-service.sh
        
        if sudo ./install-service.sh; then
            print_success "Serviço instalado e iniciado!"
        else
            print_warning "Falha ao instalar serviço. Continue com a instalação manual."
        fi
    else
        print_warning "Script de instalação do serviço não encontrado."
    fi
fi

# Limpeza opcional
if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Deseja manter os arquivos de desenvolvimento? (y/N): " -n 1 -r
    echo ""
    CLEANUP="$REPLY"
else
    # Modo não-interativo: fazer limpeza por padrão
    print_status "Limpando arquivos desnecessários..."
    CLEANUP="n"
fi

if [[ ! $CLEANUP =~ ^[Yy]$ ]]; then
    print_status "🧹 Limpando arquivos desnecessários..."
    cd "$INSTALL_DIR"
    rm -rf node_modules .git yarn.lock
    find . -name "*.js" -not -path "./dist/*" -not -path "./bin/*" -delete 2>/dev/null || true
    find . -name "*.json" -not -path "./dist/*" -not -path "./bin/*" -delete 2>/dev/null || true
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