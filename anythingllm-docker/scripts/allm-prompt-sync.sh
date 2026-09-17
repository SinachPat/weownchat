#!/usr/bin/env bash
# allm-prompt-sync.sh — bring an AnythingLLM workspace system prompt under
# version control, without the admin API key ever crossing an agent's
# context, argv, a log, or a PR diff.
#
# WHY THIS EXISTS (see docs/design/DESIGN-client-intake-and-agent-workflows.md,
# Phase 1): the agent's entire behaviour — persona, disclaimers, refusals,
# follow-ups — currently lives ONLY in the AnythingLLM runtime database.
# Terraform, compose, the MCP pack and Ansible are all strict IaC; the system
# prompt is the one artifact in this product with no review, no CI, no
# rollback and no drift detection. Two instances can answer an identically
# worded question differently on the same git SHA and nothing in the repo
# would show it. This script is the seam: PULL bootstraps a committed copy
# from a live instance, DIFF detects drift, PUSH applies a reviewed change.
#
# FIELD NAME IS UNCONFIRMED AGAINST THIS DEPLOYMENT. AnythingLLM's documented
# workspace-update contract uses `openAiPrompt` as the system-prompt field on
# `POST /api/v1/workspace/:slug/update`, regardless of the configured
# provider (legacy naming) — but no AnythingLLM source is vendored in this
# repo to verify that against, and API surfaces do change between releases.
# Run `discover` FIRST, on every new instance, before trusting `pull`/`push`.
# `discover` is a plain GET — it can never modify the workspace.
#
# The admin API key is read with `read -rs` and travels
# operator's terminal -> curl's Authorization header only. It is never an
# argument, never echoed, never written to disk, and never visible in `ps`.
# RUN THIS SCRIPT YOURSELF, in your own terminal — do not paste the key into
# a command an agent executes on your behalf; that puts the secret in the
# agent's transcript, which is exactly what this script exists to avoid
# doing to the PROMPT (a lesser but real exposure) let alone the KEY.
#
# Depends on `curl` and `jq` (JSON extraction/construction without hand-built
# string escaping — the prompt text will contain quotes and newlines, and
# hand-rolled JSON is exactly the kind of thing not to build by hand).
#
# Usage:
#   ./allm-prompt-sync.sh discover <allm-url> <workspace-slug>
#   ./allm-prompt-sync.sh pull     <allm-url> <workspace-slug> <output-file>
#   ./allm-prompt-sync.sh diff     <allm-url> <workspace-slug> <committed-file>
#   ./allm-prompt-sync.sh push     <allm-url> <workspace-slug> <committed-file>
#
# <allm-url> is the AnythingLLM API base reachable from wherever you run this
# — typically an SSH tunnel to the droplet's internal `anythingllm:3001`, or
# `http://localhost:3001` if you are already on the box. This script makes no
# SSH call itself; it assumes you have already arranged reachability, the
# same separation `allm-admin-account.sh` keeps between transport and action.
#
# Example (bootstrap the dev instance's public prompt):
#   ssh -L 3001:localhost:3001 root@<dev-droplet-ip> -N &
#   ./allm-prompt-sync.sh discover http://localhost:3001 dev-weown-public
#   ./allm-prompt-sync.sh pull http://localhost:3001 dev-weown-public \
#       ../sites/dev-weown-anythingllm/prompts/public.md
set -euo pipefail

for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: '$bin' is required but not found on PATH" >&2; exit 1; }
done

MODE="${1:?usage: allm-prompt-sync.sh {discover|pull|diff|push} <allm-url> <workspace-slug> [file]}"
ALLM_URL="${2:?ALLM API base URL required, e.g. http://localhost:3001}"
SLUG="${3:?workspace slug required}"
FILE="${4:-}"

case "$MODE" in
  discover) ;;
  pull|diff) [[ -n "$FILE" ]] || { echo "ERROR: $MODE requires a file argument" >&2; exit 1; } ;;
  push) [[ -n "$FILE" ]] || { echo "ERROR: push requires a committed file argument" >&2; exit 1; } ;;
  *) echo "ERROR: mode must be discover, pull, diff or push" >&2; exit 1 ;;
esac

# zsh-safe prompt: `read -p` is a coprocess operator in zsh, not a prompt.
printf 'AnythingLLM admin API key for %s (hidden): ' "$ALLM_URL" >&2
read -rs API_KEY; echo >&2
[[ -n "$API_KEY" ]] || { echo "ERROR: empty key" >&2; exit 1; }

RESP="$(mktemp -t allm-prompt-sync)"
trap 'rm -f "$RESP"' EXIT

fetch_workspace() {
  local http_code
  http_code="$(curl -sS -o "$RESP" -w '%{http_code}' \
    -H "Authorization: Bearer ${API_KEY}" \
    -H 'Accept: application/json' \
    "${ALLM_URL%/}/api/v1/workspace/${SLUG}")"
  if [[ "$http_code" != "200" ]]; then
    echo "ERROR: GET /api/v1/workspace/${SLUG} returned HTTP ${http_code}" >&2
    cat "$RESP" >&2
    exit 1
  fi
  # AnythingLLM returns { "workspace": [ {...} ] } — an ARRAY even for one
  # workspace (verified server-side precedent in template/dashboard/server.js,
  # dashboard's own `allm()` caller notes this exact shape at line ~421).
  if ! jq -e '(.workspace // [{}])[0]' "$RESP" > /dev/null 2>&1; then
    echo "ERROR: unexpected response shape from GET /api/v1/workspace/${SLUG}:" >&2
    cat "$RESP" >&2
    exit 1
  fi
}

# Extracts .openAiPrompt from the fetched workspace object, or fails loud —
# never silently writes an empty/null prompt over a real one.
extract_prompt() {
  local prompt
  prompt="$(jq -e -r '(.workspace // [{}])[0].openAiPrompt // empty' "$RESP")" || {
    echo "ERROR: no 'openAiPrompt' field on this workspace object — run 'discover' and update this script for the field this AnythingLLM version actually uses" >&2
    exit 1
  }
  printf '%s' "$prompt"
}

case "$MODE" in
  discover)
    fetch_workspace
    echo "Workspace object keys on this instance (confirm the prompt field before using pull/push):" >&2
    jq -r '(.workspace // [{}])[0] | to_entries[] | "  \(.key): \(.value | tostring | gsub("\n"; "\\n") | if length > 60 then .[0:60] + "..." else . end)"' "$RESP" >&2
    ;;

  pull)
    fetch_workspace
    extract_prompt > "$FILE"
    echo "Wrote current live prompt for '${SLUG}' to ${FILE}" >&2
    echo "Review it, then commit it — this file is now the source of truth." >&2
    ;;

  diff)
    fetch_workspace
    LIVE="$(mktemp -t allm-prompt-live)"
    trap 'rm -f "$RESP" "$LIVE"' EXIT
    extract_prompt > "$LIVE"
    if diff -u "$FILE" "$LIVE" >&2; then
      echo "No drift: '${SLUG}' matches ${FILE}" >&2
    else
      echo "DRIFT DETECTED on '${SLUG}' — live prompt does not match ${FILE}" >&2
      exit 3
    fi
    ;;

  push)
    [[ -f "$FILE" ]] || { echo "ERROR: ${FILE} not found" >&2; exit 1; }
    fetch_workspace
    LIVE="$(mktemp -t allm-prompt-live)"
    PAYLOAD="$(mktemp -t allm-prompt-payload)"
    trap 'rm -f "$RESP" "$LIVE" "$PAYLOAD"' EXIT
    extract_prompt > "$LIVE"

    echo "--- live (current) vs. ${FILE} (about to apply) ---" >&2
    diff -u "$LIVE" "$FILE" >&2 || true
    printf "\nApply the above change to workspace '%s' on %s? Type YES to confirm: " "$SLUG" "$ALLM_URL" >&2
    read -r CONFIRM
    [[ "$CONFIRM" == "YES" ]] || { echo "Aborted — nothing changed." >&2; exit 1; }

    # jq -Rs slurps the file as raw text into a single JSON string — the safe
    # way to carry arbitrary quotes/newlines/backslashes into a JSON payload
    # without hand-built escaping.
    jq -Rs '{openAiPrompt: .}' "$FILE" > "$PAYLOAD"

    http_code="$(curl -sS -o "$RESP" -w '%{http_code}' \
      -X POST \
      -H "Authorization: Bearer ${API_KEY}" \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      --data @"$PAYLOAD" \
      "${ALLM_URL%/}/api/v1/workspace/${SLUG}/update")"
    if [[ "$http_code" != "200" ]]; then
      echo "ERROR: POST /api/v1/workspace/${SLUG}/update returned HTTP ${http_code}" >&2
      cat "$RESP" >&2
      exit 1
    fi
    echo "Applied ${FILE} to '${SLUG}'. Re-run diff to confirm." >&2
    ;;
esac
