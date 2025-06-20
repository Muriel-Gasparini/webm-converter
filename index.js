#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { exec, spawn } = require("child_process");

const watchFolder =
  process.env.WEBM_WATCH_DIR || `${process.env.HOME}/Videos/Screencasts`;
const checkInterval = 3000; // Checa crescimento do arquivo a cada 3 segundos
const finalWait = 5000; // Aguarda 5s extras antes da conversão
const pendingFiles = new Map();

console.log(`📂 Monitorando a pasta: ${watchFolder}...`);

// Verificar se o ffmpeg está instalado
function checkFfmpeg() {
  return new Promise((resolve, reject) => {
    exec("ffmpeg -version", (error, stdout, stderr) => {
      if (error) {
        console.error(`❌ FFmpeg não encontrado!`);
        console.error(
          `💡 Instale o FFmpeg: sudo apt update && sudo apt install ffmpeg`
        );
        reject(error);
      } else {
        const version = stdout.split("\n")[0];
        console.log(`✅ ${version}`);
        resolve();
      }
    });
  });
}

// Verificar o ffmpeg antes de iniciar o monitoramento
checkFfmpeg()
  .then(() => {
    console.log(`🔧 FFmpeg verificado e funcionando`);
    startWatching();
  })
  .catch(() => {
    process.exit(1);
  });

function startWatching() {
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
}

function convertFile(inputPath, outputPath) {
  console.log(`🚀 Iniciando conversão de ${path.basename(inputPath)}...`);

  const ffmpegArgs = [
    "-i",
    inputPath,
    "-c:v",
    "libx264",
    "-c:a",
    "aac",
    "-profile:v",
    "main",
    "-pix_fmt",
    "yuv420p",
    "-crf",
    "23",
    "-preset",
    "veryfast",
    "-vf",
    "scale=1280:-2",
    "-r",
    "30",
    "-f",
    "mp4",
    "-y", // Sobrescrever arquivo de saída se existir
    outputPath,
  ];

  const ffmpeg = spawn("ffmpeg", ffmpegArgs);

  let duration = null;
  let progress = null;

  ffmpeg.stderr.on("data", (data) => {
    const output = data.toString();

    // Capturar duração total do vídeo
    if (!duration) {
      const durationMatch = output.match(
        /Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})/
      );
      if (durationMatch) {
        const hours = parseInt(durationMatch[1]);
        const minutes = parseInt(durationMatch[2]);
        const seconds = parseFloat(durationMatch[3]);
        duration = hours * 3600 + minutes * 60 + seconds;
      }
    }

    // Capturar progresso atual
    const timeMatch = output.match(/time=(\d{2}):(\d{2}):(\d{2}\.\d{2})/);
    if (timeMatch && duration) {
      const hours = parseInt(timeMatch[1]);
      const minutes = parseInt(timeMatch[2]);
      const seconds = parseFloat(timeMatch[3]);
      const currentTime = hours * 3600 + minutes * 60 + seconds;
      const percent = (currentTime / duration) * 100;

      if (percent > 0 && percent <= 100) {
        console.log(
          `⌛ Progresso (${path.basename(inputPath)}): ${percent.toFixed(2)}%`
        );
      }
    }
  });

  ffmpeg.on("close", (code) => {
    if (code === 0) {
      console.log(`✅ Conversão concluída: ${outputPath}`);
    } else {
      console.error(
        `❌ Erro na conversão de ${path.basename(inputPath)} (código: ${code})`
      );
    }
    pendingFiles.delete(inputPath);
  });

  ffmpeg.on("error", (err) => {
    console.error(
      `❌ Erro ao executar ffmpeg para ${path.basename(inputPath)}:`,
      err.message
    );
    pendingFiles.delete(inputPath);
  });
}
