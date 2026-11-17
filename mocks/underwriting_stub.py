#!/usr/bin/env python3
"""Downstream 'underwriting' stub you can break on demand. Standard library only.

  python3 underwriting_stub.py                # listens on :8090
  POST /underwriting        -> 200 {"decision": ...}  (or 503 while failing)
  POST /admin/fail          -> start returning 503
  POST /admin/ok            -> recover
  GET  /health              -> current state
"""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "8090"))
STATE = {"failing": False, "count": 0}


class Handler(BaseHTTPRequestHandler):
    def _json(self, code, obj):
        data = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/health":
            self._json(200, {"failing": STATE["failing"], "handled": STATE["count"]})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        if self.path == "/admin/fail":
            STATE["failing"] = True
            print("[underwriting] now FAILING (503)", flush=True)
            self._json(200, {"failing": True})
        elif self.path == "/admin/ok":
            STATE["failing"] = False
            print("[underwriting] recovered", flush=True)
            self._json(200, {"failing": False})
        elif self.path == "/underwriting":
            if STATE["failing"]:
                print(f"[underwriting] 503 for: {body[:120]}", flush=True)
                self._json(503, {"error": "underwriting unavailable"})
            else:
                STATE["count"] += 1
                print(f"[underwriting] OK for: {body[:120]}", flush=True)
                self._json(200, {"decision": "REFERRED_FOR_REVIEW", "handled": STATE["count"]})
        else:
            self._json(404, {"error": "not found"})

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"[underwriting] listening on :{PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
