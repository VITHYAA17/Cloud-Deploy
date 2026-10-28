#!/usr/bin/env bash
# ==============================================================================
# Script: semgrep-scan.sh
# Purpose: Execute Semgrep SAST scanning with configurable security thresholds
# ==============================================================================

set -eo pipefail

REPORT_DIR="${REPORT_DIR:-reports/security}"
REPORT_JSON="${REPORT_DIR}/semgrep-report.json"
CONFIG_FILE="${CONFIG_FILE:-.semgrep.yml}"
FAIL_ON_SEVERITY="${FAIL_ON_SEVERITY:-ERROR}" # ERROR or WARNING

mkdir -p "${REPORT_DIR}"

echo "=========================================================="
echo " Starting Semgrep Static Application Security Testing (SAST)"
echo " Rule Config: ${CONFIG_FILE}"
echo " Output File: ${REPORT_JSON}"
echo " Fail Level : ${FAIL_ON_SEVERITY}"
echo "=========================================================="

if command -v semgrep &> /dev/null; then
    SCAN_CMD="semgrep scan --config=${CONFIG_FILE} --config=p/owasp-top-ten --config=p/java --json --output=${REPORT_JSON} --error"
elif command -v docker &> /dev/null; then
    echo "Semgrep binary not found on PATH. Executing via official Docker container..."
    SCAN_CMD="docker run --rm -v $(pwd):/src returntocorp/semgrep semgrep scan --config=/src/${CONFIG_FILE} --config=p/owasp-top-ten --config=p/java --json --output=/src/${REPORT_JSON} --error"
else
    echo "ERROR: Neither Semgrep CLI nor Docker is available."
    exit 1
fi

set +e
${SCAN_CMD}
EXIT_CODE=$?
set -e

if [ ${EXIT_CODE} -eq 0 ]; then
    echo "SUCCESS: Semgrep SAST scan passed with 0 critical security flaws."
    exit 0
else
    echo "SECURITY GATE FAILED: Semgrep identified potential vulnerabilities matching threshold (${FAIL_ON_SEVERITY})."
    echo "Review findings in ${REPORT_JSON} before promoting to next pipeline stage."
    exit ${EXIT_CODE}
fi
