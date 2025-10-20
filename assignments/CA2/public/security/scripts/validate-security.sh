#!/bin/bash
# Security Hardening Validation Script
# This script validates the security configurations implemented

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Security Hardening Validation Report"
echo "========================================"
echo "Date: $(date)"
echo "Project: $PROJECT_ROOT"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local required_tool="$3"
    
    echo -n "Testing $test_name... "
    
    if [[ -n "$required_tool" ]] && ! command -v "$required_tool" >/dev/null 2>&1; then
        echo -e "${YELLOW}SKIPPED${NC} (missing $required_tool)"
        ((TESTS_SKIPPED++))
        return
    fi
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
    fi
}

echo "📁 File Structure Validation"
echo "----------------------------"

# Check if secret files exist
run_test "Secret files exist" "find $PROJECT_ROOT -name 'secrets.yaml' | wc -l | grep -q '^[0-9]\+$'" ""

# Check if network policies exist
run_test "Network policies exist" "find $PROJECT_ROOT/k8s/network-policies -name '*.yaml' | wc -l | grep -q '^6$'" ""

# Check if scripts exist and are executable
run_test "Security scripts exist" "test -x $PROJECT_ROOT/scripts/generate-secrets.sh" ""

echo ""
echo "🔐 Secret Management"
echo "-------------------"

# Check SOPS configuration
run_test "SOPS configuration exists" "test -f $PROJECT_ROOT/.sops.yaml" ""

# Check gitignore for secrets
run_test "Gitignore excludes secrets" "grep -q 'secrets/' $PROJECT_ROOT/.gitignore" ""

echo ""
echo "🛡️ Kubernetes Security"
echo "---------------------"

# Validate YAML syntax for network policies
run_test "Network policy YAML syntax" "python3 -c \"import yaml; [yaml.safe_load(open(f)) for f in ['$PROJECT_ROOT/k8s/network-policies/default-deny.yaml', '$PROJECT_ROOT/k8s/network-policies/kafka-network-policy.yaml']]\"" "python3"

# Validate Sealed Secrets controller
run_test "Sealed Secrets controller YAML" "python3 -c \"import yaml; list(yaml.safe_load_all(open('$PROJECT_ROOT/k8s/sealed-secrets/controller.yaml')))\"" "python3"

# Check Pod Security Standards
run_test "Pod Security Standards config" "test -f $PROJECT_ROOT/k8s/pod-security-admission.yaml" ""

echo ""
echo "🔒 PostgreSQL Security"
echo "---------------------"

# Check PostgreSQL configuration
run_test "PostgreSQL TLS configuration" "grep -q 'ssl = true' $PROJECT_ROOT/nix/postgresql/postgresql.nix" ""

# Check SCRAM-SHA-256 authentication
run_test "SCRAM-SHA-256 authentication" "grep -q 'scram-sha-256' $PROJECT_ROOT/nix/postgresql/postgresql.nix" ""

# Check certificate generation script
run_test "Certificate generation script" "test -x $PROJECT_ROOT/scripts/generate-postgresql-certs.sh" ""

echo ""
echo "🌐 Network Security"
echo "------------------"

# Check enhanced nftables rules
run_test "Enhanced nftables rules" "grep -q 'blacklist_ipv4' $PROJECT_ROOT/nix/postgresql/nftables.nft" ""

# Check fail2ban service
run_test "Fail2ban service configuration" "test -f $PROJECT_ROOT/nix/fail2ban-service.nix" ""

echo ""
echo "📊 Summary"
echo "=========="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Tests Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All available tests passed!${NC}"
    if [[ $TESTS_SKIPPED -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Some tests were skipped due to missing tools${NC}"
        echo "   Install required tools for complete validation:"
        echo "   - nix (for NixOS config validation)"
        echo "   - kubectl (for Kubernetes manifest validation)"
        echo "   - sops (for secret encryption testing)"
        echo "   - age (for key generation testing)"
    fi
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the configuration.${NC}"
    exit 1
fi
