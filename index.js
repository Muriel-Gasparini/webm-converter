#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { exec, spawn } = require("child_process");
const notifier = require("node-notifier");

function getIconPath() {
  const possiblePaths = [
    path.resolve(__dirname, "icon.png"),
    path.resolve(process.cwd(), "icon.png"),
    path.resolve(path.dirname(process.execPath), "icon.png"),
    "/usr/local/share/webm-converter/icon.png",
    path.resolve(process.env.HOME, ".local/share/webm-converter/icon.png"),
  ];

  for (const iconPath of possiblePaths) {
    if (fs.existsSync(iconPath)) {
      return iconPath;
    }
  }

  return undefined;
}

const iconPath = getIconPath();

const watchFolder =
  process.env.WEBM_WATCH_DIR || `${process.env.HOME}/Videos/Screencasts`;
const checkInterval = 3000;
const finalWait = 5000;
const pendingFiles = new Map();

console.log(`[INFO] Monitoring directory: ${watchFolder}`);
if (iconPath) {
  console.log(`[INFO] Icon found at: ${iconPath}`);
} else {
  console.log(`[WARN] Icon not found - notifications without icon`);
}

function checkFfmpeg() {
  return new Promise((resolve, reject) => {
    exec("ffmpeg -version", (error, stdout, stderr) => {
      if (error) {
        console.error(`[ERROR] FFmpeg not found`);
        console.error(
          `[INFO] Install FFmpeg: sudo apt update && sudo apt install ffmpeg`
        );
        reject(error);
      } else {
        const version = stdout.split("\n")[0];
        console.log(`[SUCCESS] ${version}`);
        resolve();
      }
    });
  });
}

checkFfmpeg()
  .then(() => {
    console.log(`[INFO] FFmpeg verified and operational`);

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
      console.log(`[INFO] File removed: ${filename}, ignoring...`);
      return;
    }

    if (fs.existsSync(outputPath)) {
      console.log(`[WARN] Ignored: ${filename} already has corresponding .mp4`);
      return;
    }

    if (pendingFiles.has(inputPath)) return;
    console.log(
      `[INFO] File detected: ${filename}, waiting for recording completion...`
    );

    pendingFiles.set(inputPath, { lastSize: 0 });

    const checkFile = () => {
      const currentSize = fs.statSync(inputPath).size;
      const fileData = pendingFiles.get(inputPath);

      if (currentSize === fileData.lastSize) {
        exec(`lsof "${inputPath}"`, (err, stdout) => {
          if (stdout.trim()) {
            setTimeout(checkFile, checkInterval);
          } else {
            console.log(
              `[SUCCESS] Recording finished: ${filename}, waiting for safety period...`
            );

            notifier.notify({
              title: "WebM Converter",
              message: "Starting conversion...",
              icon: iconPath,
              sound: false,
              wait: false,
            });

            setTimeout(() => convertFile(inputPath, outputPath), finalWait);
          }
        });
      } else {
        pendingFiles.set(inputPath, { lastSize: currentSize });
        setTimeout(checkFile, checkInterval);
      }
    };

    setTimeout(checkFile, checkInterval);
  });
}

function convertFile(inputPath, outputPath) {
  console.log(`[INFO] Starting conversion of ${path.basename(inputPath)}...`);

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
    "-y",
    outputPath,
  ];

  const ffmpeg = spawn("ffmpeg", ffmpegArgs);

  let duration = null;
  let progress = null;

  ffmpeg.stderr.on("data", (data) => {
    const output = data.toString();

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

    const timeMatch = output.match(/time=(\d{2}):(\d{2}):(\d{2}\.\d{2})/);
    if (timeMatch && duration) {
      const hours = parseInt(timeMatch[1]);
      const minutes = parseInt(timeMatch[2]);
      const seconds = parseFloat(timeMatch[3]);
      const currentTime = hours * 3600 + minutes * 60 + seconds;
      const percent = (currentTime / duration) * 100;

      if (percent > 0 && percent <= 100) {
        console.log(
          `[PROGRESS] ${path.basename(inputPath)}: ${percent.toFixed(2)}%`
        );
      }
    }
  });

  ffmpeg.on("close", (code) => {
    if (code === 0) {
      console.log(`[SUCCESS] Conversion completed: ${outputPath}`);

      notifier.notify({
        title: "WebM Converter",
        message: "Conversion completed successfully!",
        icon: iconPath,
        sound: true,
        wait: false,
      });
    } else {
      console.error(
        `[ERROR] Conversion failed for ${path.basename(inputPath)} (exit code: ${code})`
      );

      notifier.notify({
        title: "WebM Converter",
        message: "Conversion failed!",
        icon: iconPath,
        sound: true,
        wait: false,
      });
    }
    pendingFiles.delete(inputPath);
  });

  ffmpeg.on("error", (err) => {
    console.error(
      `[ERROR] Failed to execute ffmpeg for ${path.basename(inputPath)}:`,
      err.message
    );

    notifier.notify({
      title: "WebM Converter",
      message: "Fatal conversion error!",
      icon: iconPath,
      sound: true,
      wait: false,
    });

    pendingFiles.delete(inputPath);
  });
}
