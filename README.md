# WebM Converter 🎬

Conversor automático de arquivos .webm para .mp4 especialmente otimizado para gravações do Gnome ScreenCast.

## 🚀 Instalação com UM comando

```bash
curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/main/install.sh | bash
```

**Isso é tudo!** ✨ O script vai:

- ✅ Verificar dependências (Node.js, Git)
- ✅ Baixar e compilar o projeto
- ✅ Instalar o executável em `~/.local/bin`
- ✅ Configurar o PATH automaticamente
- ✅ Criar pasta de vídeos `~/Videos/Screencasts`
- ✅ Oferecer instalação como serviço systemd
- ✅ Limpar arquivos desnecessários

## 🎯 Como funciona

1. **Grave sua tela** usando o Gnome ScreenCast (Ctrl+Alt+Shift+R)
2. **Arquivos .webm são detectados** automaticamente em `~/Videos/Screencasts`
3. **Conversão automática** para .mp4 com configurações otimizadas
4. **Zero intervenção** necessária!

## 📋 Pré-requisitos

- **Linux** com systemd
- **Node.js 18+** (o script ajuda a instalar)
- **Git** (`sudo apt install git`)

## 🎮 Uso

### Como Executável

```bash
# Executar uma vez (monitoramento manual)
webm-converter

# Parar com Ctrl+C
```

### Como Serviço (Recomendado)

```bash
# Ver status
sudo systemctl status webm-converter

# Parar/Iniciar
sudo systemctl stop webm-converter
sudo systemctl start webm-converter

# Ver logs em tempo real
sudo journalctl -u webm-converter -f
```

## ⚙️ Configurações

- **Pasta monitorada**: `~/Videos/Screencasts` (padrão do Gnome)
- **Formato de saída**: MP4 (H.264 + AAC)
- **Resolução**: Redimensionado para 1280px de largura
- **Taxa de quadros**: 30 FPS
- **Qualidade**: CRF 23 (boa qualidade/tamanho)

### Personalizar pasta:

```bash
export WEBM_WATCH_DIR="/outra/pasta"
webm-converter
```

## 🗑️ Desinstalação

```bash
curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/main/uninstall.sh | bash
```

## 🔧 Para Desenvolvedores

### Build manual:

```bash
git clone https://github.com/Muriel-Gasparini/webm-converter.git
cd webm-converter
yarn install
yarn build:linux
```

### Instalar serviço local:

```bash
sudo ./install-service.sh
```

## 📁 Estrutura do Projeto

```
webm-converter/
├── 📱 index.js              # Código principal
├── 📦 package.json          # Dependências e scripts
├── 🔧 webm-converter.service # Template do serviço
├── 🚀 install.sh            # Instalador automático
├── 🗑️ uninstall.sh          # Desinstalador
├── ⚙️ install-service.sh     # Instalador do serviço
├── ❌ uninstall-service.sh   # Desinstalador do serviço
├── 📖 README-SERVICE.md     # Docs do serviço
└── 📦 dist/                 # Executável compilado
```

## 🐛 Solução de Problemas

### WebM Converter não inicia:

```bash
# Verificar logs
sudo journalctl -u webm-converter --since "1 hour ago"

# Testar manualmente
webm-converter
```

### FFmpeg não encontrado:

```bash
# Definir caminho personalizado
export FFMPEG_PATH="/caminho/para/ffmpeg"
```

### Pasta não monitorada:

```bash
# Verificar se a pasta existe
ls -la ~/Videos/Screencasts

# Criar se necessário
mkdir -p ~/Videos/Screencasts
```

## 🎬 Demo

1. Pressione `Ctrl+Alt+Shift+R` para iniciar gravação
2. Grave sua tela normalmente
3. Pressione `Ctrl+Alt+Shift+R` novamente para parar
4. Aguarde alguns segundos
5. ✨ Arquivo `.mp4` aparece automaticamente na mesma pasta!

## 📊 Características

- 🚀 **Zero configuração** - Funciona imediatamente
- 🔄 **Monitoramento automático** - Detecta fim da gravação
- 📦 **FFmpeg bundled** - Não precisa instalar dependências
- 🎯 **Otimizado para ScreenCast** - Configurações ideais
- 🔧 **Serviço systemd** - Inicia com o sistema
- 📱 **Executável standalone** - Um arquivo de 110MB
- 🧹 **Auto-limpeza** - Remove arquivos temporários

## 📄 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

**Criado para facilitar a vida de quem grava screencasts no Linux!** 🐧✨
