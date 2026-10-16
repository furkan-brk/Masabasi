#!/usr/bin/env bash
set -euo pipefail

if [[ "${GITHUB_EVENT_NAME:-}" != "push" ]]; then
  echo "CI gate skipped for ${GITHUB_EVENT_NAME:-unknown} event."
  exit 0
fi

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"

workflow_file="${CI_WORKFLOW_FILE:-ci.yml}"
branch="${CI_BRANCH:-main}"
attempts="${CI_GATE_ATTEMPTS:-90}"
sleep_seconds="${CI_GATE_SLEEP_SECONDS:-10}"

echo "Waiting for ${workflow_file} on ${branch}@${GITHUB_SHA}..."

for attempt in $(seq 1 "$attempts"); do
  if ! run_state="$(
    gh api \
      --method GET \
      -H "Accept: application/vnd.github+json" \
      "/repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow_file}/runs" \
      -f head_sha="${GITHUB_SHA}" \
      -f branch="${branch}" \
      -f event=push \
      -f per_page=5 \
      --jq '.workflow_runs | sort_by(.created_at) | reverse | .[0] // empty | [.status, (.conclusion // "")] | @tsv'
  )"; then
    echo "gh api call failed, retrying (${attempt}/${attempts})..."
    sleep "$sleep_seconds"
    continue
  fi

  if [[ -z "$run_state" ]]; then
    echo "CI run not visible yet (${attempt}/${attempts})."
    sleep "$sleep_seconds"
    continue
  fi

  status="${run_state%%$'\t'*}"
  conclusion="${run_state#*$'\t'}"

  case "${status}:${conclusion}" in
    completed:success)
      echo "CI passed; deployment may continue."
      exit 0
      ;;
    completed:*)
      echo "CI finished with conclusion '${conclusion}'. Blocking deployment."
      exit 1
      ;;
    *)
      echo "CI status is '${status}' (${attempt}/${attempts})."
      sleep "$sleep_seconds"
      ;;
  esac
done

echo "Timed out waiting for CI after $((attempts * sleep_seconds)) seconds."
exit 1
