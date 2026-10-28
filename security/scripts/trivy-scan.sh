#!/usr/bin/env bash
# ==============================================================================
# Script: trivy-scan.sh
# Purpose: Execute Trivy vulnerability scanning on filesystems and Docker images
# Usage:
#   ./trivy-scan.sh fs <path>
#   ./trivy-scan.sh image <image-tag>
# ==============================================================================

set -eo pipefail

SCAN_TYPE="${1:-fs}"
TARGET="${2:-app}"
REPORT_DIR="${REPORT_DIR:-reports/security}"
CONFIG_FILE="${CONFIG_FILE:-security/trivy/trivy.yaml}"
SEVERITY_LEVELS="${SEVERITY_LEVELS:-HIGH,CRITICAL}"

mkdir -p "${REPORT_DIR}"

echo "=========================================================="
echo " Starting Trivy Security Vulnerability Scanner"
echo " Scan Mode    : ${SCAN_TYPE}"
echo " Target       : ${TARGET}"
echo " Severity Gate: ${SEVERITY_LEVELS}"
echo "=========================================================="

# Check if Trivy is locally installed or use Docker container
run_trivy() {
    local args="$@"
    if command -v trivy &> /dev/null; then
        trivy ${args}
    elif command -v docker &> /dev/null; then
        docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v $(pwd):/workspace \
            aquasec/trivy:latest ${args}
    else
        echo "ERROR: Neither trivy CLI nor Docker is available."
        exit 1
    fi
}

case "${SCAN_TYPE}" in
    fs)
        REPORT_FILE="${REPORT_DIR}/trivy-fs-report.json"
        echo "Scanning filesystem and application dependencies in ${TARGET}..."
        
        # Human readable summary
        run_trivy fs --severity "${SEVERITY_LEVELS}" --ignore-unfixed "${TARGET}" || true

        # Generate report and enforce security gate
        set +e
        run_trivy fs --format json --output "${REPORT_FILE}" --severity "${SEVERITY_LEVELS}" --exit-code 1 --ignore-unfixed "${TARGET}"
        EXIT_CODE=$?
        set -e
        ;;

    image)
        REPORT_FILE="${REPORT_DIR}/trivy-image-report.json"
        echo "Scanning container image ${TARGET} for OS and library vulnerabilities..."
        
        # Human readable summary
        run_trivy image --severity "${SEVERITY_LEVELS}" --ignore-unfixed "${TARGET}" || true

        # Generate report and enforce security gate
        set +e
        run_trivy image --format json --output "${REPORT_FILE}" --severity "${SEVERITY_LEVELS}" --exit-code 1 --ignore-unfixed "${TARGET}"
        EXIT_CODE=$?
        set -e
        ;;

    *)
        echo "Invalid scan type: ${SCAN_TYPE}. Use 'fs' or 'image'."
        exit 1
        ;;
esac

if [ ${EXIT_CODE} -eq 0 ]; then
    echo "SUCCESS: Trivy scan passed! No ${SEVERITY_LEVELS} vulnerabilities detected in ${TARGET}."
    exit 0
else
    echo "SECURITY GATE FAILED: Detected ${SEVERITY_LEVELS} vulnerabilities in ${TARGET} exceeding defined security thresholds!"
    echo "See detailed report in ${REPORT_FILE}"
    exit ${EXIT_CODE}
fi
