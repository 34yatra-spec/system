/* Transient voice companion — vanilla, no deps. */
"use strict";
const $ = (id) => document.getElementById(id);
const els = {
  net: $("net"), cfg: $("cfg"), acct: $("acct"), token: $("token"), client: $("client"),
  save: $("save"), cfgState: $("cfgState"), qr: $("qr"), mobileUrl: $("mobileUrl"),
  openMobile: $("openMobile"), session: $("session"), reload: $("reload"), newSes: $("newSes"),
  mic: $("mic"), micLabel: $("micLabel"), micTimer: $("micTimer"), stt: $("stt"),
  transcript: $("transcript"), text: $("text"), send: $("send"), log: $("log"),
  speak: $("speak"),
};
const store = {
  get(k, d) { try { const v = localStorage.getItem(k); return v == null ? d : v; } catch { return d; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch {} },
};
const qp = new URLSearchParams(location.search);
const ROLE = (qp.get("role") || "").toLowerCase();
let CLIENT = qp.get("client") || store.get("transient:client", "");
let SESSION = store.get("transient:session", "");
let CFG = null;

function setNet(mode, txt) { if (els.net) { els.net.className = "net " + mode; els.net.textContent = txt; } }
function setStt(txt) { if (els.stt) els.stt.textContent = txt; }
function api(path, opts) {
  const sep = path.includes("?") ? "&" : "?";
  const url = CLIENT ? path + sep + "client=" + encodeURIComponent(CLIENT) : path;
  opts = opts || {};
  opts.headers = Object.assign({"X-Client-Id": CLIENT}, opts.headers || {});
  return fetch(url, opts);
}

async function loadConfig() {
  setNet("retry", "linking…");
  let r;
  try { r = await fetch("/api/config"); } catch { setNet("retry", "server unreachable"); return; }
  if (!r.ok) { setNet("retry", "config failed"); return; }
  CFG = await r.json();
  setNet("online", "linked ✓");
  if (!CLIENT && CFG.clientId) { CLIENT = CFG.clientId; store.set("transient:client", CLIENT); }
  if (CFG.clientId && els.client && !els.client.value) els.client.value = CFG.clientId;
  if (CFG.accountMasked && els.acct && !els.acct.value) els.acct.placeholder = "saved (" + CFG.accountMasked + ")";
  const saved = CFG.savedAccount && CFG.savedToken;
  if (els.cfgState) els.cfgState.textContent = saved ? "saved ✓ — collapsed, open to change" : "not set — STT/TTS fall back to on-device browser voice";
  if (els.cfg && saved) els.cfg.open = false; else if (els.cfg) els.cfg.open = true;
  const url = CFG.mobileUrl || (location.origin + "/?role=mobile");
  if (els.mobileUrl) els.mobileUrl.textContent = url;
  if (els.qr) els.qr.src = "https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=" + encodeURIComponent(url);
  if (els.openMobile) els.openMobile.href = url;
}

async function loadSessions() {
  let r;
  try { r = await api("/api/sessions?n=20"); } catch { return; }
  if (!r.ok) return;
  const j = await r.json().catch(() => null);
  const list = (j && j.sessions) || [];
  if (!els.session) return;
  els.session.innerHTML = "";
  const fresh = document.createElement("option");
  fresh.value = ""; fresh.textContent = "+ new session";
  els.session.appendChild(fresh);
  for (const s of list) {
    const o = document.createElement("option");
    o.value = s.id; o.textContent = (s.title || s.id).slice(0, 60);
    els.session.appendChild(o);
  }
  if (SESSION) els.session.value = SESSION;
}
function currentSession() { return (els.session && els.session.value) || ""; }

function pushLog(who, text) {
  if (!els.log) return;
  const li = document.createElement("li");
  li.className = who === "me" ? "me" : "bot";
  const k = document.createElement("span"); k.className = "k";
  k.textContent = who === "me" ? "YOU · " + new Date().toLocaleTimeString() : "OPENCODE · " + new Date().toLocaleTimeString();
  const s = document.createElement("span"); s.textContent = text;
  li.append(k, s);
  els.log.prepend(li);
  try {
    const h = JSON.parse(store.get("transient:hist", "[]"));
    h.unshift({who, text: text.slice(0, 2000), ts: Date.now()});
    store.set("transient:hist", JSON.stringify(h.slice(0, 20)));
  } catch {}
}
function renderHist() {
  try {
    const h = JSON.parse(store.get("transient:hist", "[]"));
    for (const m of h.slice().reverse()) pushLog(m.who, m.text);
  } catch {}
}

/* ---------- speech out ---------- */
async function speak(text) {
  if (!text || !els.speak || !els.speak.checked) return;
  try {
    const r = await api("/api/tts", {method: "POST", headers: {"Content-Type": "application/json"},
      body: JSON.stringify({text: text.slice(0, 4000)})});
    if (r.ok) {
      const blob = await r.blob();
      const url = URL.createObjectURL(blob);
      const a = new Audio(url);
      await a.play().catch(() => fallbackSpeak(text));
      return;
    }
  } catch {}
  fallbackSpeak(text);
}
function fallbackSpeak(text) {
  try {
    if (!window.speechSynthesis) return;
    speechSynthesis.cancel();
    speechSynthesis.speak(new SpeechSynthesisUtterance(text.slice(0, 1000)));
  } catch {}
}

/* ---------- send to opencode ---------- */
let polling = false;
async function deliver(text) {
  text = (text || "").trim();
  if (!text) return;
  pushLog("me", text);
  setStt("sending to opencode…");
  let r;
  try {
    r = await api("/api/input", {method: "POST", headers: {"Content-Type": "application/json"},
      body: JSON.stringify({text, sessionId: currentSession(), client: CLIENT})});
  } catch { setStt("error: server unreachable"); return; }
  if (r.status === 403) { setStt("error: wrong client id — rescan the QR"); return; }
  if (!r.ok) { setStt("error: " + r.status); return; }
  const j = await r.json().catch(() => null);
  if (!j || !j.jobId) { setStt("error: bad reply"); return; }
  pollJob(j.jobId);
}
async function pollJob(id) {
  if (polling) return;
  polling = true;
  setStt("opencode is working…");
  try {
    for (let i = 0; i < 200; i++) {
      await new Promise((res) => setTimeout(res, 1500));
      let r;
      try { r = await api("/api/job/" + id); } catch { continue; }
      if (!r.ok) continue;
      const j = await r.json();
      if (j.status === "done") {
        if (j.sessionId && els.session) {
          SESSION = j.sessionId; store.set("transient:session", SESSION);
          await loadSessions();
        }
        if (els.transcript) els.transcript.textContent = j.answer || "(empty)";
        pushLog("bot", j.answer || "(empty)");
        setStt("✓ reply ready — speaking");
        speak(j.answer || "");
        break;
      }
      if (j.status === "error") { setStt("error: " + (j.error || "failed").slice(0, 160)); break; }
      if (i % 4 === 0) setStt("opencode is working… " + Math.round(i * 1.5) + "s");
    }
  } finally { polling = false; }
}

/* ---------- mic ---------- */
let mediaStream = null, recorder = null, chunks = [], recording = false, recT0 = 0, tickT = null;
function fmtT(ms) { const s = Math.floor(ms / 1000); return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0"); }
function pickMime() {
  const c = ["audio/webm;codecs=opus", "audio/webm", "audio/mp4"];
  for (const m of c) { try { if (window.MediaRecorder && MediaRecorder.isTypeSupported(m)) return m; } catch {} }
  return "";
}
async function toggleMic() {
  recording ? await stopAndSend() : await startRec();
}
async function startRec() {
  try {
    mediaStream = await navigator.mediaDevices.getUserMedia({audio: {echoCancellation: true, noiseSuppression: true, channelCount: 1}});
  } catch { setStt("mic blocked — allow microphone"); return; }
  chunks = [];
  const mime = pickMime();
  try { recorder = mime ? new MediaRecorder(mediaStream, {audioBitsPerSecond: 16000}) : new MediaRecorder(mediaStream); }
  catch { setStt("recorder unsupported here — type instead"); stopTracks(); return; }
  if (mime) { try { recorder.mimeType = mime; } catch {} }
  recorder.ondataavailable = (e) => { if (e.data && e.data.size) chunks.push(e.data); };
  recorder.start(250);
  recording = true; recT0 = Date.now();
  els.mic.classList.add("rec");
  els.micLabel.textContent = "● TAP TO STOP";
  clearInterval(tickT);
  tickT = setInterval(() => { els.micTimer.textContent = fmtT(Date.now() - recT0); }, 250);
  setStt("listening…");
}
async function stopAndSend() {
  if (!recorder || recorder.state === "inactive") { recording = false; stopTracks(); return; }
  const done = new Promise((res) => { recorder.onstop = res; });
  try { recorder.stop(); } catch {}
  await done;
  recording = false;
  clearInterval(tickT);
  stopTracks();
  els.mic.classList.remove("rec");
  els.micLabel.textContent = "TRANSCRIBING…";
  const blob = new Blob(chunks, {type: (recorder && recorder.mimeType) || "audio/webm"});
  chunks = [];
  if (blob.size < 800) { setStt("too short — hold a bit longer"); els.micLabel.textContent = "TAP TO TALK"; return; }
  setStt("transcribing…");
  const text = await transcribe(blob);
  els.micLabel.textContent = "TAP TO TALK";
  if (!text) { setStt("heard nothing — try again"); return; }
  if (els.transcript) els.transcript.textContent = text;
  await deliver(text);
}
function stopTracks() { try { mediaStream && mediaStream.getTracks().forEach((t) => t.stop()); } catch {} mediaStream = null; }
async function transcribe(blob) {
  try {
    const r = await api("/api/stt", {method: "POST", headers: {"Content-Type": blob.type || "audio/webm"}, body: blob});
    if (r.ok) {
      const j = await r.json().catch(() => null);
      if (j && j.text) return j.text.trim();
      return "";
    }
    if (r.status === 400) return await browserRecognize(blob); // creds missing -> on-device
  } catch {}
  try { return await browserRecognize(blob); } catch { return ""; }
}
/* On-device fallback: Web Speech API needs mic directly, so we run one
 * short recognition pass. If unavailable, return "" and the user types. */
function browserRecognize() {
  return new Promise((resolve) => {
    try {
      const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SR) return resolve("");
      const rec = new SR();
      rec.lang = "en-US"; rec.interimResults = false; rec.maxAlternatives = 1;
      setStt("on-device listening… speak now");
      rec.onresult = (e) => resolve(e.results[0][0].transcript || "");
      rec.onerror = () => resolve("");
      rec.onend = () => resolve("");
      rec.start();
      setTimeout(() => { try { rec.stop(); } catch {} resolve(""); }, 12000);
    } catch { resolve(""); }
  });
}

/* ---------- wiring ---------- */
if (els.mic) els.mic.addEventListener("click", toggleMic);
if (els.send) els.send.onclick = async () => { const v = els.text.value.trim(); if (!v) return; els.text.value = ""; await deliver(v); };
if (els.text) els.text.addEventListener("keydown", (e) => { if (e.key === "Enter") { e.preventDefault(); els.send.click(); } });
if (els.save) els.save.onclick = async () => {
  const body = {accountId: els.acct.value.trim(), apiToken: els.token.value, clientId: els.client.value.trim().toUpperCase()};
  if (!body.accountId || !body.apiToken || !body.clientId) { els.cfgState.textContent = "fill all three fields"; return; }
  const r = await fetch("/api/config", {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify(body)});
  if (r.ok) {
    els.token.value = "";
    CLIENT = body.clientId; store.set("transient:client", CLIENT);
    els.cfgState.textContent = "saved ✓";
    await loadConfig();
  } else els.cfgState.textContent = "save failed";
};
if (els.session) els.session.onchange = () => { SESSION = els.session.value; store.set("transient:session", SESSION); };
if (els.reload) els.reload.onclick = loadSessions;
if (els.newSes) els.newSes.onclick = async () => { if (els.session) els.session.value = ""; SESSION = ""; store.set("transient:session", ""); setStt("new session — next message starts it"); };

if (ROLE === "mobile" && document.body) document.body.classList.add("mobile");
renderHist();
loadConfig().then(loadSessions);
api("/api/last").then((r) => r.ok ? r.json() : null).then((j) => {
  if (j && j.answer && els.transcript && els.transcript.textContent.trim() === "—") els.transcript.textContent = j.answer;
}).catch(() => {});
