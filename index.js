#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;

ffmpeg.setFfmpegPath(ffmpegPath);

const watchFolder = "/home/tiuras/Videos/Screencasts";
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
