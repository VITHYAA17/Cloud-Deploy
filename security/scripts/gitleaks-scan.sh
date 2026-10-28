#!/usr/bin/env bash
# ==============================================================================
# Script: gitleaks-scan.sh
# Purpose: Execute Gitleaks secret detection with configurable security gate
# ==============================================================================

set -eo pipefail

REPORT_DIR="${REPORT_DIR:-reports/security}"
REPORT_FILE="${REPORT_DIR}/gitleaks-report.json"
CONFIG_FILE="${CONFIG_FILE:-.gitleaks.toml}"
EXIT_ON_LEAK="${EXIT_ON_LEAK:-true}"

mkdir -p "${REPORT_DIR}"

echo "=========================================================="
echo " Starting Gitleaks Secret Detection"
echo " Configuration: ${CONFIG_FILE}"
echo " Report Output: ${REPORT_FILE}"
echo "=========================================================="

if command -v gitleaks &> /dev/null; then
    SCAN_CMD="gitleaks detect --config=${CONFIG_FILE} --report-path=${REPORT_FILE} --report-format=json --verbose"
elif command -v docker &> /dev/null; then
    echo "Gitleaks binary not found on PATH. Executing via official Docker image..."
    SCAN_CMD="docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source=/path --config=/path/${CONFIG_FILE} --report-path=/path/${REPORT_FILE} --report-format=json --verbose"
else
    echo "ERROR: Neither gitleaks CLI nor Docker is available."
    exit 1
fi

set +e
${SCAN_CMD}
EXIT_CODE=$?
set -e

if [ ${EXIT_CODE} -eq 0 ]; then
    echo "SUCCESS: No secrets or credentials leaked in codebase."
    exit 0
else
    echo "CRITICAL: Secrets detected in git repository! Check ${REPORT_FILE} for details."
    if [ "${EXIT_ON_LEAK}" = "true" ]; then
        echo "Security Gate Failed: Halting CI/CD pipeline."
        exit ${EXIT_CODE}
    else
        echo "WARNING: Gate bypassed per EXIT_ON_LEAK configuration."
        exit 0
    fi
fi
