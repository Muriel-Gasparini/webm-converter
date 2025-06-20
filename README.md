# WebM Converter 🎬

Conversor automático de arquivos .webm para .mp4 especialmente otimizado para gravações do Gnome ScreenCast.

## 🚀 Instalação com UM comando

```bash
curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/master/install.sh | bash
```

**Isso é tudo!** ✨ O script vai:

- ✅ Instalar FFmpeg via apt (se não estiver presente)
- ✅ Baixar binário pré-compilado da release v1.0.0
- ✅ Instalar o executável em `~/.local/bin`
- ✅ Configurar o PATH automaticamente
- ✅ Criar pasta de vídeos `~/Videos/Screencasts`
- ✅ Oferecer instalação como serviço systemd

> 💡 **Para desinstalar:** `curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/master/uninstall.sh | bash`

## 🎯 Como funciona

1. **Grave sua tela** usando o Gnome ScreenCast (Ctrl+Alt+Shift+R)
2. **Arquivos .webm são detectados** automaticamente em `~/Videos/Screencasts`
3. **Conversão automática** para .mp4 com configurações otimizadas
4. **Zero intervenção** necessária!

## 📋 Pré-requisitos

- **Linux** com systemd
- **FFmpeg** (instalado automaticamente via apt)
- **curl** ou **wget** (`sudo apt install curl`)

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
curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/master/uninstall.sh | bash
```

**Isso é tudo!** 🧹 O script vai:

- ✅ Parar e remover o serviço systemd
- ✅ Remover executável de `~/.local/bin`
- ✅ Perguntar se quer remover FFmpeg do sistema
- ✅ Opção para fazer limpeza de pacotes órfãos

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
├── 📱 index.js              # Código principal (usa ffmpeg via spawn)
├── 📦 package.json          # Configuração pkg + Node.js 18
├── 🔧 webm-converter.service # Template do serviço
├── 🚀 install.sh            # Instalador automático (download release)
├── 🗑️ uninstall.sh          # Desinstalador (pergunta sobre ffmpeg)
├── ⚙️ install-service.sh     # Instalador do serviço
├── ❌ uninstall-service.sh   # Desinstalador do serviço
└── 📦 dist/                 # Executável compilado (~46MB)
```

## 🐛 Solução de Problemas

### WebM Converter não inicia:

```bash
# Verificar logs
sudo journalctl -u webm-converter --since "1 hour ago"

# Testar manualmente
webm-converter

# Verificar se ffmpeg está instalado
ffmpeg -version
```

### FFmpeg não encontrado:

```bash
# Instalar FFmpeg
sudo apt update && sudo apt install ffmpeg

# Verificar instalação
which ffmpeg
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

- 🚀 **Instalação rápida** - Download direto da release
- 🔄 **Monitoramento automático** - Detecta fim da gravação
- 🛠️ **FFmpeg nativo** - Usa FFmpeg do sistema (via apt)
- 🎯 **Otimizado para ScreenCast** - Configurações ideais
- 🔧 **Serviço systemd** - Inicia com o sistema
- 📱 **Executável standalone** - ~46MB (sem dependências externas)
- 🐧 **Linux específico** - Otimizado para distribuições Linux

## 🆕 Arquitetura v1.0.0

- **FFmpeg via apt**: Usa o FFmpeg instalado no sistema
- **Sem dependências Node.js**: Executável self-contained
- **Spawn nativo**: child_process.spawn para máxima performance
- **Release binária**: Download direto, sem necessidade de compilação

## 📄 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

**Criado para facilitar a vida de quem grava screencasts no Linux!** 🐧✨
