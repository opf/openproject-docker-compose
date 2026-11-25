#!/usr/bin/env bash
# Global Livesolutions stack health check — runs from the OpenProject host.
# Checks all Cloudflare Tunnel public endpoints plus local stack components.
# Returns 0 only if all monitored endpoints pass.

set -euo pipefail

PASS=0
FAIL=0

check_url() {
  local name="$1"
  local url="$2"
  local expected="${3:-200}"
  local code
  code=$(curl -sS -L --max-time 20 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  if [ "$code" = "$expected" ]; then
    echo "[PASS] $name ($url) -> HTTP $code"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $name ($url) -> HTTP $code (expected $expected)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Global Stack Health Check ==="
echo "Timestamp: $(date -Iseconds)"
echo

# Public Cloudflare Tunnel endpoints (status subdomain has no Access)
check_url "status endpoint"     "https://status.livesolutionsnow.com/healthz" "200"
check_url "OpenProject login"     "https://projects.livesolutionsnow.com/login" "200"
check_url "OpenProject root"      "https://projects.livesolutionsnow.com"       "200"
check_url "AI stack"              "https://ai.livesolutionsnow.com"             "200"
check_url "n8n"                   "https://n8n.livesolutionsnow.com"            "200"
check_url "flows"                 "https://flows.livesolutionsnow.com"          "200"
check_url "comfy"                 "https://comfy.livesolutionsnow.com"          "200"
check_url "leads"                 "https://leads.livesolutionsnow.com"          "200"
check_url "qbo"                   "https://qbo.livesolutionsnow.com"            "404"
check_url "qbo-internal"          "https://qbo-internal.livesolutionsnow.com"   "200"
check_url "design"                "https://design.livesolutionsnow.com"         "200"
check_url "webhooks"              "https://webhooks.livesolutionsnow.com"       "200"

echo
echo "=== Local Docker Health ==="
local_status=$(docker compose -f /home/anthonyturgman/openproject/docker-compose.yml -f /home/anthonyturgman/openproject/docker-compose.override.yml ps --format json 2>/dev/null || true)
if [ -n "$local_status" ]; then
  echo "$local_status" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        r = json.loads(line)
        svc = r.get('Service', r.get('Name','unknown'))
        health = r.get('Health', 'unknown')
        state = r.get('State', 'unknown')
        if health == 'healthy' or state == 'running':
            print(f'[PASS] {svc} -> {health}/{state}')
        else:
            print(f'[FAIL] {svc} -> {health}/{state}')
    except Exception:
        pass
" || echo "[WARN] Could not parse local compose health"
else
  echo "[WARN] Could not read local compose health"
fi

echo
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: ALL OK"
  exit 0
else
  echo "RESULT: FAILURES DETECTED"
  exit 1
fi
