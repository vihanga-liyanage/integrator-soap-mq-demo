#!/usr/bin/env python3
"""Tiny SOAP 1.1 / 1.2 mock for the demo. Standard library only.

  python3 soap_mock.py            # listens on :8089
  GET  http://localhost:8089/customer?wsdl     -> customer.wsdl
  POST http://localhost:8089/customer          -> GetCustomer
"""
import hashlib
import os
import re
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "8089"))
HERE = os.path.dirname(os.path.abspath(__file__))
NS = "http://americannational.example/customer"

CUSTOMERS = {
    "C1001": ("Jordan Avery", 12, "ACTIVE"),
    "C1002": ("Priya Raman", 47, "ACTIVE"),
    "C1003": ("Marcus Webb", 81, "REVIEW"),
}

ENV11 = ('<?xml version="1.0" encoding="utf-8"?>'
         '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
         '<soap:Body>{body}</soap:Body></soap:Envelope>')
ENV12 = ('<?xml version="1.0" encoding="utf-8"?>'
         '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">'
         '<soap:Body>{body}</soap:Body></soap:Envelope>')


def lookup(cid):
    if cid in CUSTOMERS:
        return CUSTOMERS[cid]
    h = int(hashlib.sha1(cid.encode()).hexdigest(), 16)
    return (f"Customer {cid}", h % 100, "ACTIVE")


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.split("?")[0] in ("/customer", "/") and "wsdl" in self.path.lower():
            with open(os.path.join(HERE, "customer.wsdl"), encoding="utf-8") as f:
                self._send(200, f.read(), "text/xml; charset=utf-8")
        else:
            self._send(404, "not found", "text/plain")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length).decode("utf-8", errors="replace")
        is12 = "application/soap+xml" in self.headers.get("Content-Type", "")
        envelope = ENV12 if is12 else ENV11
        ctype = "application/soap+xml; charset=utf-8" if is12 else "text/xml; charset=utf-8"

        m = re.search(r"<(?:\w+:)?customerId[^>]*>\s*([^<]*?)\s*</(?:\w+:)?customerId>", raw)
        if not m or not m.group(1):
            fault = ("<soap:Fault><faultcode>soap:Client</faultcode>"
                     "<faultstring>customerId is required</faultstring></soap:Fault>"
                     if not is12 else
                     "<soap:Fault><soap:Code><soap:Value>soap:Sender</soap:Value></soap:Code>"
                     "<soap:Reason><soap:Text xml:lang=\"en\">customerId is required</soap:Text></soap:Reason></soap:Fault>")
            self._send(500, envelope.format(body=fault), ctype)
            return

        cid = m.group(1)
        name, risk, status = lookup(cid)
        body = (f'<GetCustomerResponse xmlns="{NS}">'
                f"<customerId>{cid}</customerId><fullName>{name}</fullName>"
                f"<riskScore>{risk}</riskScore><status>{status}</status>"
                f"</GetCustomerResponse>")
        print(f"[soap_mock] GetCustomer {cid} -> {name}, risk {risk} ({'1.2' if is12 else '1.1'})", flush=True)
        self._send(200, envelope.format(body=body), ctype)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"[soap_mock] listening on :{PORT}  (WSDL: http://localhost:{PORT}/customer?wsdl)", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
