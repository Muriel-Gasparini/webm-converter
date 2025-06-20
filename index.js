#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
const ffmpeg = require("fluent-ffmpeg");

// Função para encontrar o ffmpeg
function findFfmpeg() {
  // Se estivermos rodando como executável pkg, extrair ffmpeg para temp
  if (process.pkg) {
    const os = require("os");
    const tempDir = os.tmpdir();
    const tempFfmpeg = path.join(tempDir, "webm-converter-ffmpeg");

    try {
      // Tentar ler o ffmpeg bundled
      const bundledFfmpeg = path.join(__dirname, "bin", "ffmpeg");
      if (fs.existsSync(bundledFfmpeg)) {
        // Copiar para temp se não existir ou for diferente
        if (!fs.existsSync(tempFfmpeg)) {
          fs.copyFileSync(bundledFfmpeg, tempFfmpeg);
          fs.chmodSync(tempFfmpeg, 0o755);
          console.log(`📦 FFmpeg extraído para: ${tempFfmpeg}`);
        }
        return tempFfmpeg;
      }
    } catch (error) {
      console.log("⚠️ Erro ao extrair ffmpeg bundled:", error.message);
    }
  }

  // Primeiro, tentar usar ffmpeg local (para desenvolvimento)
  const localFfmpeg = path.join(__dirname, "bin", "ffmpeg");
  if (fs.existsSync(localFfmpeg)) {
    return localFfmpeg;
  }

  // Se estiver em desenvolvimento, tentar usar o @ffmpeg-installer
  try {
    const ffmpegInstaller = require("@ffmpeg-installer/ffmpeg");
    const bundledPath = ffmpegInstaller.path;

    // Verificar se o arquivo existe
    if (fs.existsSync(bundledPath)) {
      return bundledPath;
    }
  } catch (installerError) {
    console.log(
      "⚠️ @ffmpeg-installer não disponível, tentando alternativas..."
    );
  }

  // Tentar usar ffmpeg do sistema
  try {
    require("child_process").execSync("which ffmpeg", { stdio: "ignore" });
    return "ffmpeg";
  } catch (error) {
    // Última tentativa: usar variável de ambiente
    return process.env.FFMPEG_PATH || "ffmpeg";
  }
}

const ffmpegPath = findFfmpeg();
console.log(`🔧 Usando ffmpeg: ${ffmpegPath}`);

// Verificar se o ffmpeg funciona
try {
  require("child_process").execSync(`"${ffmpegPath}" -version`, {
    stdio: "ignore",
  });
  console.log(`✅ FFmpeg verificado e funcionando`);
} catch (error) {
  console.error(`❌ Erro ao verificar ffmpeg em: ${ffmpegPath}`);
  console.error(
    `💡 Defina FFMPEG_PATH: export FFMPEG_PATH=/caminho/para/ffmpeg`
  );
  process.exit(1);
}

ffmpeg.setFfmpegPath(ffmpegPath);

const watchFolder =
  process.env.WEBM_WATCH_DIR || `${process.env.HOME}/Videos/Screencasts`;
const checkInterval = 3000; // Checa crescimento do arquivo a cada 3 segundos
const finalWait = 5000; // Aguarda 5s extras antes da conversão
const pendingFiles = new Map();

console.log(`📂 Monitorando a pasta: ${watchFolder}...`);

fs.watch(watchFolder, (eventType, filename) => {
  if (!filename || path.extname(filename) !== ".webm") return;

  const inputPath = path.join(watchFolder, filename);
  const outputPath = inputPath.replace(".webm", ".mp4");

  if (!fs.existsSync(inputPath)) {
    console.log(`🗑️ Arquivo removido: ${filename}, ignorando...`);
    return;
  }

  if (fs.existsSync(outputPath)) {
    console.log(`⚠️ Ignorado: ${filename} já tem um .mp4 correspondente.`);
    return;
  }

  if (pendingFiles.has(inputPath)) return;
  console.log(
    `📌 Arquivo detectado: ${filename}, aguardando o fim da gravação...`
  );
  pendingFiles.set(inputPath, { lastSize: 0 });

  const checkFile = () => {
    const currentSize = fs.statSync(inputPath).size;
    const fileData = pendingFiles.get(inputPath);

    if (currentSize === fileData.lastSize) {
      exec(`lsof "${inputPath}"`, (err, stdout) => {
        if (stdout.trim()) {
          // Arquivo ainda está sendo gravado
          setTimeout(checkFile, checkInterval);
        } else {
          // Gravação finalizada
          console.log(
            `✅ Gravação finalizada: ${filename}, aguardando segurança...`
          );
          setTimeout(() => convertFile(inputPath, outputPath), finalWait);
        }
      });
    } else {
      // O arquivo está crescendo
      pendingFiles.set(inputPath, { lastSize: currentSize });
      setTimeout(checkFile, checkInterval);
    }
  };

  setTimeout(checkFile, checkInterval);
});

function convertFile(inputPath, outputPath) {
  console.log(`🚀 Iniciando conversão de ${path.basename(inputPath)}...`);

  ffmpeg(inputPath)
    .output(outputPath)
    .videoCodec("libx264")
    .audioCodec("aac")
    .format("mp4")
    .addOptions([
      "-profile:v main",
      "-pix_fmt yuv420p",
      "-crf 23",
      "-preset veryfast",
      "-vf scale=1280:-2",
      "-r 30",
    ])
    .on("progress", (progress) => {
      if (progress.percent) {
        console.log(
          `⌛ Progresso (${path.basename(
            inputPath
          )}): ${progress.percent.toFixed(2)}%`
        );
      }
    })
    .on("end", () => {
      console.log(`✅ Conversão concluída: ${outputPath}`);
      pendingFiles.delete(inputPath);
    })
    .on("error", (err) => {
      console.error(
        `❌ Erro na conversão de ${path.basename(inputPath)}:`,
        err.message
      );
      pendingFiles.delete(inputPath);
    })
    .run();
}
