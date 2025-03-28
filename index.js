#!/usr/bin/env node
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;
const path = require("path");

ffmpeg.setFfmpegPath(ffmpegPath);

const inputPath = process.argv[2];
if (!inputPath) {
  console.error("Erro: Especifique um arquivo de entrada.");
  process.exit(1);
}

const outputPath = inputPath.replace(path.extname(inputPath), ".mp4");

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
      console.log(`Progresso: ${progress.percent.toFixed(2)}%`);
    }
  })
  .on("end", () => {
    console.log(`Conversão concluída! Arquivo salvo em: ${outputPath}`);
  })
  .on("error", (err) => {
    console.error("Erro na conversão:", err.message);
  })
  .run();
