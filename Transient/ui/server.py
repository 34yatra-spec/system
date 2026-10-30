#!/usr/bin/env python3
"""Transient voice companion UI — stdlib only, no pip deps.

Serves a desktop+mobile page on the LAN:
  settings (Cloudflare Workers AI creds + client id, collapsible once saved)
  QR of the mobile URL, big mic button, opencode session select,
  voice in (STT) -> opencode run -> answer out (TTS).

Endpoints:
  GET  /                        index.html (desktop+mobile, ?role=mobile for mic-first)
  GET  /app.js /style.css       static
  GET  /api/health              {ok, ui, time}
  GET  /api/config              saved flags + masked account + clientId + lanIp + mobileUrl (never the token)
  POST /api/config              {accountId, apiToken, clientId, sttModel?, ttsModel?} -> 0600 file
  GET  /api/sessions?n=20       via `opencode session list`
  POST /api/input               {text, sessionId?, client} -> {jobId} (async, polls via /api/job)
  GET  /api/job/<id>            {status, answer?, error?}
  GET  /api/last?client=        latest done answer for this client (page reload safe)
  POST /api/stt                 raw audio bytes -> {text} via Cloudflare Workers AI (or 400 stt-not-configured)
  POST /api/tts                 {text} -> audio bytes via Cloudflare Workers AI (or 400 tts-not-configured)

Pairing: once a clientId is saved, mobile calls must send it (?client= or X-Client-Id).
This is pet-project grade pairing, not real auth. LAN exposure is intentional.

Test only: TRANSIENT_UI_DRYRUN=1 makes /api/input answer without calling opencode.
"""
import json
import os
import socket
import subprocess
import threading
import time
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from uuid import uuid4

VERSION = "1"
DEFAULT_PORT = 17874
RUN_TIMEOUT_S = 300
ANSWER_LIMIT = 8000

HERE = Path(__file__).resolve().parent
STATIC = HERE / "static"


def config_home() -> Path:
    base = os.environ.get("XDG_CONFIG_HOME") or str(Path.home() / ".config")
    p = Path(base) / "transient"
    p.mkdir(parents=True, exist_ok=True)
    return p


def config_path() -> Path:
    return config_home() / "config.json"


def load_config() -> dict:
    try:
        return json.loads(config_path().read_text())
    except Exception:
        return {}


def save_config(cfg: dict) -> None:
    cp = config_path()
    cp.write_text(json.dumps(cfg, indent=2))
    try:
        os.chmod(cp, 0o600)
    except Exception:
        pass


def lan_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(2)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        pass
    try:
        return socket.gethostbyname(socket.gethostname())
    except Exception:
        return "127.0.0.1"


JOBS: dict = {}
JOBS_LOCK = threading.Lock()
LAST: dict = {}  # client -> {answer, sessionId, ts}


def check_client(qs: dict, headers, saved: dict) -> bool:
    want = str(saved.get("clientId") or "").strip()
    if not want:
        return True  # first run, no pairing yet
    got = ""
    if "client" in qs:
        got = qs["client"][0] if isinstance(qs["client"], list) else qs["client"]
    if not got:
        got = headers.get("X-Client-Id", "") or headers.get("x-client-id", "")
    return str(got).strip() == want


def run_opencode_answer(text: str, session_id: str) -> tuple:
    """Returns (answer, used_session). Raises on failure."""
    if os.environ.get("TRANSIENT_UI_DRYRUN") == "1":
        time.sleep(1)
        return ("DRYRUN echo: " + text[:2000], session_id or "dryrun-session")
    cmd = ["opencode", "run", "--format", "json"]
    if session_id:
        cmd += ["-s", session_id]
    cmd += [text]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=RUN_TIMEOUT_S)
    except FileNotFoundError:
        raise RuntimeError("opencode binary not found on server")
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"opencode run timed out after {RUN_TIMEOUT_S}s")
    out = (p.stdout or "").strip()
    if p.returncode != 0:
        err = (p.stderr or out)[-2000:]
        raise RuntimeError(f"opencode run failed (rc={p.returncode}): {err}")
    answer = extract_answer(out)
    used = session_id or guess_session(out) or "unknown"
    return (answer[:ANSWER_LIMIT], used)


def extract_answer(stream: str) -> str:
    texts = []
    for line in stream.splitlines():
        line = line.strip()
        if not line or not line.startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except Exception:
            continue
        for t in walk_texts(ev):
            if t.strip():
                texts.append(t)
    if texts:
        return texts[-1].strip()
    return stream[-4000:].strip() or "(empty answer)"


def walk_texts(node):
    if isinstance(node, dict):
        t = node.get("type")
        if t == "text" and isinstance(node.get("text"), str):
            yield node["text"]
        for v in node.values():
            yield from walk_texts(v)
    elif isinstance(node, list):
        for v in node:
            yield from walk_texts(v)


def guess_session(stream: str) -> str:
    for line in stream.splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                ev = json.loads(line)
                sid = ev.get("sessionID") or ev.get("sessionId") or ev.get("session_id")
                if sid:
                    return str(sid)
            except Exception:
                pass
    return ""


def list_sessions(n: int):
    try:
        p = subprocess.run(
            ["opencode", "session", "list", "-n", str(n), "--format", "json"],
            capture_output=True, text=True, timeout=30,
        )
    except FileNotFoundError:
        raise RuntimeError("opencode binary not found on server")
    out = (p.stdout or "").strip()
    if p.returncode != 0:
        raise RuntimeError((p.stderr or out)[-1000:])
    try:
        data = json.loads(out)
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            for k in ("sessions", "data", "items"):
                if isinstance(data.get(k), list):
                    return data[k]
        return []
    except Exception:
        return []


def cf_post(account: str, token: str, model: str, body: bytes, content_type: str):
    url = f"https://api.cloudflare.com/client/v4/accounts/{account}/ai/run/{model}"
    req = urllib.request.Request(
        url, data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": content_type},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, r.headers.get("Content-Type", ""), r.read()
    except urllib.error.HTTPError as e:
        return e.code, "application/json", e.read()


class Handler(BaseHTTPRequestHandler):
    server_version = "TransientUI/" + VERSION

    def log_message(self, *a):
        pass

    def _send(self, code: int, body: bytes, ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code: int, obj) -> None:
        self._send(code, json.dumps(obj).encode(), "application/json")

    def _qs(self) -> dict:
        from urllib.parse import urlparse, parse_qs
        return parse_qs(urlparse(self.path).query)

    def do_GET(self):
        from urllib.parse import urlparse
        path = urlparse(self.path).path
        if path == "/" or path == "/index.html":
            return self._static("index.html", "text/html; charset=utf-8")
        if path in ("/app.js", "/style.css"):
            ctype = "text/javascript; charset=utf-8" if path.endswith(".js") else "text/css; charset=utf-8"
            return self._static(path[1:], ctype)
        if path == "/api/health":
            return self._json(200, {"ok": True, "ui": "transient", "version": VERSION, "time": int(time.time())})
        if path == "/api/config":
            return self._config_get()
        if path == "/api/sessions":
            return self._sessions()
        if path.startswith("/api/job/"):
            return self._job_get(path.rsplit("/", 1)[-1])
        if path == "/api/last":
            return self._last()
        return self._json(404, {"error": "not-found"})

    def do_POST(self):
        from urllib.parse import urlparse
        path = urlparse(self.path).path
        if path == "/api/config":
            return self._config_post()
        if path == "/api/input":
            return self._input()
        if path == "/api/stt":
            return self._stt()
        if path == "/api/tts":
            return self._tts()
        return self._json(404, {"error": "not-found"})

    def _static(self, name: str, ctype: str):
        f = STATIC / name
        if not f.exists():
            return self._json(404, {"error": "missing static: " + name})
        return self._send(200, f.read_bytes(), ctype)

    def _config_get(self):
        cfg = load_config()
        acct = str(cfg.get("cfAccountId") or "")
        port = int(getattr(self.server, "ui_port", DEFAULT_PORT))
        ip = lan_ip()
        client = str(cfg.get("clientId") or "")
        mobile = f"http://{ip}:{port}/?role=mobile" + (f"&client={client}" if client else "")
        return self._json(200, {
            "savedAccount": bool(acct),
            "accountMasked": ("…" + acct[-4:] if len(acct) > 4 else ("set" if acct else "")),
            "savedToken": bool(cfg.get("cfApiToken")),
            "clientId": client,
            "sttModel": cfg.get("sttModel") or "@cf/openai/whisper-large-v3-turbo",
            "ttsModel": cfg.get("ttsModel") or "@cf/deepgram/aura-1",
            "lanIp": ip, "port": port, "mobileUrl": mobile,
        })

    def _config_post(self):
        try:
            n = int(self.headers.get("Content-Length", "0"))
        except Exception:
            n = 0
        try:
            data = json.loads(self.rfile.read(n) if n > 0 else b"{}")
        except Exception:
            return self._json(400, {"error": "bad-json"})
        cfg = load_config()
        if "accountId" in data and str(data["accountId"]).strip():
            cfg["cfAccountId"] = str(data["accountId"]).strip()
        if "apiToken" in data and str(data["apiToken"]).strip():
            cfg["cfApiToken"] = str(data["apiToken"]).strip()
        if "clientId" in data and str(data["clientId"]).strip():
            cfg["clientId"] = str(data["clientId"]).strip().upper()[:16]
        if "sttModel" in data and str(data["sttModel"]).strip():
            cfg["sttModel"] = str(data["sttModel"]).strip()
        if "ttsModel" in data and str(data["ttsModel"]).strip():
            cfg["ttsModel"] = str(data["ttsModel"]).strip()
        save_config(cfg)
        return self._json(200, {"ok": True})

    def _sessions(self):
        qs = self._qs()
        try:
            n = max(1, min(50, int((qs.get("n") or ["20"])[0])))
        except Exception:
            n = 20
        try:
            sessions = list_sessions(n)
        except RuntimeError as e:
            return self._json(502, {"error": str(e)})
        slim = []
        for s in sessions:
            if not isinstance(s, dict):
                continue
            sid = s.get("id") or s.get("sessionID") or s.get("session_id") or ""
            slim.append({
                "id": sid,
                "title": s.get("title") or "(untitled)",
                "directory": s.get("directory") or "",
                "time": s.get("time_created") or s.get("time") or s.get("updated") or 0,
            })
        return self._json(200, {"sessions": slim})

    def _input(self):
        cfg = load_config()
        if not check_client(self._qs(), self.headers, cfg):
            return self._json(403, {"error": "bad-client"})
        try:
            n = int(self.headers.get("Content-Length", "0"))
        except Exception:
            n = 0
        try:
            data = json.loads(self.rfile.read(n) if n > 0 else b"{}")
        except Exception:
            return self._json(400, {"error": "bad-json"})
        text = str(data.get("text") or "").strip()
        if not text:
            return self._json(400, {"error": "empty-text"})
        if len(text) > 8000:
            return self._json(400, {"error": "text-too-long"})
        session_id = str(data.get("sessionId") or "").strip()
        client = str(data.get("client") or self._qs().get("client", [""])[0] if isinstance(self._qs().get("client"), list) else data.get("client") or "").strip()
        job_id = uuid4().hex[:12]
        with JOBS_LOCK:
            JOBS[job_id] = {"status": "running", "sessionId": session_id, "text": text[:200],
                            "answer": "", "error": "", "created": int(time.time())}
        t = threading.Thread(target=self._run_job, args=(job_id, text, session_id, client), daemon=True)
        t.start()
        return self._json(200, {"jobId": job_id})

    @staticmethod
    def _run_job(job_id: str, text: str, session_id: str, client: str):
        try:
            answer, used = run_opencode_answer(text, session_id)
            with JOBS_LOCK:
                JOBS[job_id].update({"status": "done", "answer": answer, "sessionId": used})
            if client:
                LAST[client] = {"answer": answer, "sessionId": used, "ts": int(time.time())}
            LAST[""] = {"answer": answer, "sessionId": used, "ts": int(time.time())}
        except Exception as e:
            with JOBS_LOCK:
                JOBS[job_id].update({"status": "error", "error": str(e)[:2000]})

    def _job_get(self, job_id: str):
        with JOBS_LOCK:
            job = JOBS.get(job_id)
        if not job:
            return self._json(404, {"error": "no-job"})
        return self._json(200, {"jobId": job_id, **job})

    def _last(self):
        qs = self._qs()
        client = ""
        if "client" in qs:
            client = qs["client"][0] if isinstance(qs["client"], list) else qs["client"]
        hit = LAST.get(str(client)) or LAST.get("") or {}
        return self._json(200, {"answer": hit.get("answer", ""), "sessionId": hit.get("sessionId", ""),
                               "ts": hit.get("ts", 0)})

    def _stt(self):
        cfg = load_config()
        if not check_client(self._qs(), self.headers, cfg):
            return self._json(403, {"error": "bad-client"})
        acct, token = str(cfg.get("cfAccountId") or ""), str(cfg.get("cfApiToken") or "")
        if not acct or not token:
            return self._json(400, {"error": "stt-not-configured"})
        try:
            n = int(self.headers.get("Content-Length", "0"))
        except Exception:
            n = 0
        if n <= 0 or n > 12_000_000:
            return self._json(400, {"error": "bad-audio"})
        audio = self.rfile.read(n)
        ctype = self.headers.get("Content-Type", "audio/webm")
        model = cfg.get("sttModel") or "@cf/openai/whisper-large-v3-turbo"
        code, rtype, body = cf_post(acct, token, model, audio, ctype)
        if code != 200:
            return self._json(502, {"error": "stt-upstream", "detail": body[:1000].decode("utf-8", "replace")})
        try:
            j = json.loads(body)
            res = j.get("result", j)
            text = (res.get("text") if isinstance(res, dict) else str(res)) or ""
            return self._json(200, {"text": str(text).strip()})
        except Exception:
            return self._json(502, {"error": "stt-parse"})

    def _tts(self):
        cfg = load_config()
        if not check_client(self._qs(), self.headers, cfg):
            return self._json(403, {"error": "bad-client"})
        acct, token = str(cfg.get("cfAccountId") or ""), str(cfg.get("cfApiToken") or "")
        if not acct or not token:
            return self._json(400, {"error": "tts-not-configured"})
        try:
            n = int(self.headers.get("Content-Length", "0"))
        except Exception:
            n = 0
        try:
            data = json.loads(self.rfile.read(n) if n > 0 else b"{}")
        except Exception:
            return self._json(400, {"error": "bad-json"})
        text = str(data.get("text") or "").strip()[:4000]
        if not text:
            return self._json(400, {"error": "empty-text"})
        model = cfg.get("ttsModel") or "@cf/deepgram/aura-1"
        code, rtype, body = cf_post(acct, token, model,
                                    json.dumps({"text": text}).encode(), "application/json")
        if code != 200:
            return self._json(502, {"error": "tts-upstream", "detail": body[:1000].decode("utf-8", "replace")})
        if "audio" not in (rtype or "") and body[:1] == b"{":
            try:
                j = json.loads(body)
                if isinstance(j, dict) and j.get("success") is False:
                    return self._json(502, {"error": "tts-upstream", "detail": str(j)[:1000]})
            except Exception:
                pass
        return self._send(200, body, rtype or "audio/mpeg")


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=DEFAULT_PORT)
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--pidfile", default="")
    args = ap.parse_args()
    if args.pidfile:
        try:
            Path(args.pidfile).write_text(str(os.getpid()))
        except Exception:
            pass
    srv = ThreadingHTTPServer((args.host, args.port), Handler)
    srv.ui_port = args.port
    print(f"transient-ui on http://{args.host}:{args.port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
