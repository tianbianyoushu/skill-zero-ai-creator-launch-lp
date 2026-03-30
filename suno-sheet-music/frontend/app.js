"use strict";

// ---------------------------------------------------------------------------
// DOM refs
// ---------------------------------------------------------------------------
const dropZone      = document.getElementById("drop-zone");
const fileInput     = document.getElementById("file-input");
const fileInfo      = document.getElementById("file-info");
const fileNameEl    = document.getElementById("file-name");
const removeFileBtn = document.getElementById("remove-file");
const titleInput    = document.getElementById("title-input");
const convertBtn    = document.getElementById("convert-btn");

const uploadSection   = document.getElementById("upload-section");
const progressSection = document.getElementById("progress-section");
const resultSection   = document.getElementById("result-section");
const errorSection    = document.getElementById("error-section");

const progressBar = document.getElementById("progress-bar");
const progressMsg = document.getElementById("progress-message");
const step1       = document.getElementById("step-1");
const step2       = document.getElementById("step-2");
const step3       = document.getElementById("step-3");

const resultTempo  = document.getElementById("result-tempo");
const dlPianoBtn   = document.getElementById("dl-piano");
const dlGuitarBtn  = document.getElementById("dl-guitar");
const newUploadBtn = document.getElementById("new-upload-btn");
const retryBtn     = document.getElementById("retry-btn");
const errorMsg     = document.getElementById("error-message");

// Ad modal
const adModal       = document.getElementById("ad-modal");
const adModalTitle  = document.getElementById("ad-modal-title");
const adDownloadBtn = document.getElementById("ad-download-btn");
const countdownNum  = document.getElementById("countdown-number");
const countdownMsg  = document.getElementById("countdown-msg");
const closeModalBtn = document.getElementById("close-modal-btn");
const ringProgress  = document.getElementById("ring-progress");

const COUNTDOWN_SECS  = 10;
const RING_FULL       = 163.4; // 2π × r(26)

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
let selectedFile = null;
let pollTimer    = null;
let currentJobId = null;
let pianoUrl     = "";
let guitarUrl    = "";
let countTimer   = null;

// ---------------------------------------------------------------------------
// File selection
// ---------------------------------------------------------------------------
function setFile(file) {
  if (!file) return;
  selectedFile           = file;
  fileNameEl.textContent = file.name;
  fileInfo.classList.remove("hidden");
  dropZone.classList.add("hidden");
  convertBtn.disabled = false;
  if (!titleInput.value) {
    titleInput.value = file.name.replace(/\.[^.]+$/, "");
  }
}

function clearFile() {
  selectedFile    = null;
  fileInput.value = "";
  fileInfo.classList.add("hidden");
  dropZone.classList.remove("hidden");
  convertBtn.disabled = true;
}

fileInput.addEventListener("change", () => {
  if (fileInput.files.length > 0) setFile(fileInput.files[0]);
});

removeFileBtn.addEventListener("click", clearFile);

dropZone.addEventListener("click", (e) => {
  if (e.target.closest("label")) return;
  fileInput.click();
});
dropZone.addEventListener("keydown", (e) => {
  if (e.key === "Enter" || e.key === " ") { e.preventDefault(); fileInput.click(); }
});

["dragenter", "dragover"].forEach((ev) => {
  dropZone.addEventListener(ev, (e) => { e.preventDefault(); dropZone.classList.add("drag-over"); });
});
["dragleave", "drop"].forEach((ev) => {
  dropZone.addEventListener(ev, () => dropZone.classList.remove("drag-over"));
});
dropZone.addEventListener("drop", (e) => {
  e.preventDefault();
  const file = e.dataTransfer?.files?.[0];
  if (file) setFile(file);
});

document.addEventListener("dragover", (e) => e.preventDefault());
document.addEventListener("drop",     (e) => e.preventDefault());

// ---------------------------------------------------------------------------
// Convert
// ---------------------------------------------------------------------------
convertBtn.addEventListener("click", startConversion);

async function startConversion() {
  if (!selectedFile) return;
  currentJobId = null;
  showSection("progress");
  setProgress(0, "アップロード中…");
  setStepState(null);

  const formData = new FormData();
  formData.append("file", selectedFile);
  formData.append("title", titleInput.value.trim() || selectedFile.name.replace(/\.[^.]+$/, ""));

  try {
    const res = await fetch("/api/upload", { method: "POST", body: formData });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || `Upload failed (${res.status})`);
    }
    const data = await res.json();
    currentJobId = data.job_id;
    pollStatus(currentJobId);
  } catch (err) {
    showError(err.message);
  }
}

// ---------------------------------------------------------------------------
// Polling
// ---------------------------------------------------------------------------
function pollStatus(jobId) {
  clearTimeout(pollTimer);
  pollTimer = setTimeout(async () => {
    try {
      const res = await fetch(`/api/status/${jobId}`);
      if (!res.ok) throw new Error(`Status check failed (${res.status})`);
      const data = await res.json();
      handleStatus(data, jobId);
    } catch (err) {
      showError(err.message);
    }
  }, 1800);
}

function handleStatus(data, jobId) {
  const { status, progress, message, tempo_bpm } = data;
  setProgress(progress, message);
  updateSteps(progress);
  if (status === "completed") {
    showResult(jobId, tempo_bpm);
  } else if (status === "failed") {
    showError(message);
  } else {
    pollStatus(jobId);
  }
}

// ---------------------------------------------------------------------------
// Progress UI
// ---------------------------------------------------------------------------
function setProgress(pct, msg) {
  progressBar.style.width = `${pct}%`;
  progressMsg.textContent = msg || "";
}

function updateSteps(pct) {
  if (pct < 10)       setStepState(null);
  else if (pct < 55)  setStepState(1);
  else if (pct < 90)  setStepState(2);
  else                setStepState(3);
}

function setStepState(active) {
  [step1, step2, step3].forEach((el, i) => {
    const n = i + 1;
    el.classList.remove("active", "done");
    if (active === null) return;
    if (n < active)        el.classList.add("done");
    else if (n === active) el.classList.add("active");
  });
  if (active > 3) {
    step1.classList.add("done");
    step2.classList.add("done");
    step3.classList.add("done");
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------
function showResult(jobId, tempoBpm) {
  setStepState(4);
  pianoUrl  = `/api/download/${jobId}/piano`;
  guitarUrl = `/api/download/${jobId}/guitar`;
  if (tempoBpm) resultTempo.textContent = `推定テンポ: ${tempoBpm} BPM`;
  else           resultTempo.textContent = "";
  showSection("result");
}

// ダウンロードボタン → 広告ゲートを経由
dlPianoBtn.addEventListener("click",  () => openAdGate(pianoUrl,  "ピアノ譜"));
dlGuitarBtn.addEventListener("click", () => openAdGate(guitarUrl, "ギター譜"));

// ---------------------------------------------------------------------------
// Ad gate
// ---------------------------------------------------------------------------
function openAdGate(downloadUrl, label) {
  // モーダルをリセット
  clearInterval(countTimer);
  adModalTitle.textContent  = `${label}のダウンロード`;
  adDownloadBtn.href        = downloadUrl;
  adDownloadBtn.setAttribute("download", "");
  adDownloadBtn.classList.remove("unlocked");
  adDownloadBtn.classList.add("btn-locked");
  countdownNum.textContent  = COUNTDOWN_SECS;
  countdownMsg.textContent  = `${COUNTDOWN_SECS}秒後にダウンロード可能になります`;
  ringProgress.style.strokeDashoffset = 0;

  adModal.classList.remove("hidden");

  // カウントダウン開始
  let remaining = COUNTDOWN_SECS;
  countTimer = setInterval(() => {
    remaining--;
    countdownNum.textContent = remaining;

    // 円形プログレス更新
    const elapsed  = COUNTDOWN_SECS - remaining;
    const offset   = RING_FULL * (1 - elapsed / COUNTDOWN_SECS);
    ringProgress.style.strokeDashoffset = offset;

    if (remaining <= 0) {
      clearInterval(countTimer);
      // ダウンロードボタンを解放
      adDownloadBtn.classList.remove("btn-locked");
      adDownloadBtn.classList.add("unlocked");
      countdownNum.textContent = "✓";
      countdownMsg.textContent = "ダウンロードできます！";
    }
  }, 1000);
}

// モーダルを閉じる
closeModalBtn.addEventListener("click", closeAdModal);
adModal.addEventListener("click", (e) => {
  if (e.target === adModal) closeAdModal();
});

function closeAdModal() {
  clearInterval(countTimer);
  adModal.classList.add("hidden");
}

// ダウンロード後にモーダルを閉じる
adDownloadBtn.addEventListener("click", (e) => {
  if (adDownloadBtn.classList.contains("btn-locked")) {
    e.preventDefault();
    return;
  }
  setTimeout(closeAdModal, 500);
});

// ---------------------------------------------------------------------------
// Error / Navigation
// ---------------------------------------------------------------------------
function showError(msg) {
  errorMsg.textContent = msg || "不明なエラーが発生しました。";
  showSection("error");
}

function showSection(name) {
  uploadSection.classList.add("hidden");
  progressSection.classList.add("hidden");
  resultSection.classList.add("hidden");
  errorSection.classList.add("hidden");
  if (name === "upload")   uploadSection.classList.remove("hidden");
  if (name === "progress") progressSection.classList.remove("hidden");
  if (name === "result")   resultSection.classList.remove("hidden");
  if (name === "error")    errorSection.classList.remove("hidden");
}

newUploadBtn.addEventListener("click", resetUI);
retryBtn.addEventListener("click", resetUI);

function resetUI() {
  clearTimeout(pollTimer);
  currentJobId = null;
  clearFile();
  titleInput.value = "";
  showSection("upload");
}
