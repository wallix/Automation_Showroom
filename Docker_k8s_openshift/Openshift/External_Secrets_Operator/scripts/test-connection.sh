#!/usr/bin/env bash

# ==============================================================================
# WALLIX Bastion Connection Test Script for External Secrets Operator
# ==============================================================================
# This script tests the connectivity between External Secrets Operator
# and WALLIX Bastion to ensure proper configuration.
# ==============================================================================

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-production}"
SECRET_NAME="${SECRET_NAME:-wallix-bastion-credentials}"
SECRET_NAMESPACE="${SECRET_NAMESPACE:-external-secrets-system}"
SECRETSTORE_NAME="${SECRETSTORE_NAME:-wallix-bastion-store}"
TEST_ACCOUNT="${TEST_ACCOUNT:-root@local@debian}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $*"
    fi
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test WALLIX Bastion connectivity for External Secrets Operator.

OPTIONS:
    -h, --help              Show this help
    -v, --verbose           Enable verbose output
    -n, --namespace NS      Target namespace (default: $NAMESPACE)
    -s, --secret NAME       Credentials secret name (default: $SECRET_NAME)
    -t, --test-account ACC  Test account specifier (default: $TEST_ACCOUNT)
    
ENVIRONMENT VARIABLES:
    NAMESPACE               Target namespace
    SECRET_NAME             Credentials secret name
    SECRET_NAMESPACE        Credentials secret namespace
    SECRETSTORE_NAME        SecretStore name
    TEST_ACCOUNT            Account to test (format: account@target@domain)
    VERBOSE                 Enable verbose mode

EXAMPLES:
    # Basic test
    $0
    
    # Test with specific account
    $0 -t "postgres@dbserver@prod"
    
    # Verbose test with custom namespace
    $0 -v -n staging

EOF
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl >/dev/null 2>&1; then
        error "kubectl is required but not installed"
        exit 1
    fi
    
    # Check oc (optional)
    if command -v oc >/dev/null 2>&1; then
        verbose "OpenShift CLI (oc) is available"
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        error "Unable to connect to Kubernetes cluster"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

check_namespace() {
    log "Checking namespace '$NAMESPACE'..."
    
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        warning "Namespace '$NAMESPACE' does not exist"
        return 1
    fi
    
    success "Namespace '$NAMESPACE' exists"
}

check_eso_installation() {
    log "Checking External Secrets Operator installation..."
    
    # Check ESO namespace
    if ! kubectl get namespace external-secrets-system >/dev/null 2>&1; then
        error "External Secrets Operator namespace not found"
        return 1
    fi
    
    # Check ESO pods
    local eso_pods
    eso_pods=$(kubectl get pods -n external-secrets-system -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | wc -l)
    
    if [[ "$eso_pods" -eq 0 ]]; then
        error "No External Secrets Operator pods found"
        return 1
    fi
    
    verbose "Found $eso_pods ESO pods"
    
    # Check pod status
    local running_pods
    running_pods=$(kubectl get pods -n external-secrets-system -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep Running | wc -l)
    
    if [[ "$running_pods" -eq 0 ]]; then
        error "No External Secrets Operator pods are running"
        kubectl get pods -n external-secrets-system -l app.kubernetes.io/name=external-secrets
        return 1
    fi
    
    success "External Secrets Operator is running ($running_pods/$eso_pods pods)"
}

check_credentials_secret() {
    log "Checking WALLIX credentials secret..."
    
    if ! kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" >/dev/null 2>&1; then
        error "Credentials secret '$SECRET_NAME' not found in namespace '$SECRET_NAMESPACE'"
        return 1
    fi
    
    # Check required keys
    local required_keys=("username" "password" "host" "port")
    local missing_keys=()
    
    for key in "${required_keys[@]}"; do
        if ! kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.$key}" >/dev/null 2>&1; then
            missing_keys+=("$key")
        fi
    done
    
    if [[ "${#missing_keys[@]}" -gt 0 ]]; then
        error "Missing required keys in secret: ${missing_keys[*]}"
        return 1
    fi
    
    # Extract and validate credentials
    local host
    local port
    host=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.host}" | base64 -d)
    port=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.port}" | base64 -d)
    
    verbose "WALLIX Host: $host"
    verbose "WALLIX Port: $port"
    
    success "Credentials secret is properly configured"
}

check_secretstore() {
    log "Checking SecretStore configuration..."
    
    if ! kubectl get secretstore "$SECRETSTORE_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
        error "SecretStore '$SECRETSTORE_NAME' not found in namespace '$NAMESPACE'"
        return 1
    fi
    
    # Check SecretStore status
    local status
    status=$(kubectl get secretstore "$SECRETSTORE_NAME" -n "$NAMESPACE" -o jsonpath="{.status.conditions[0].status}" 2>/dev/null || echo "Unknown")
    
    verbose "SecretStore status: $status"
    
    if [[ "$status" != "True" ]]; then
        warning "SecretStore may not be ready"
        kubectl describe secretstore "$SECRETSTORE_NAME" -n "$NAMESPACE"
    else
        success "SecretStore is ready"
    fi
}

test_wallix_connectivity() {
    log "Testing WALLIX Bastion connectivity..."
    
    # Extract credentials
    local username
    local password
    local host
    local port
    
    username=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.username}" | base64 -d)
    password=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.password}" | base64 -d)
    host=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.host}" | base64 -d)
    port=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.port}" | base64 -d)
    
    # Test API version endpoint
    log "Testing API version endpoint..."
    local api_response
    api_response=$(curl -s -k --connect-timeout 10 --max-time 30 \
        "https://$host:$port/api/version" 2>&1 || echo "ERROR")
    
    if [[ "$api_response" == *"ERROR"* ]] || [[ -z "$api_response" ]]; then
        error "Unable to connect to WALLIX API at https://$host:$port"
        verbose "Response: $api_response"
        return 1
    fi
    
    verbose "API Response: $api_response"
    success "Successfully connected to WALLIX API"
    
    # Test authentication
    log "Testing authentication..."
    local auth_response
    auth_response=$(curl -s -k --connect-timeout 10 --max-time 30 \
        -u "$username:$password" \
        -X POST \
        "https://$host:$port/api" 2>&1 || echo "ERROR")
    
    # Check HTTP status
    local auth_status
    auth_status=$(curl -s -k --connect-timeout 10 --max-time 30 \
        -u "$username:$password" \
        -X POST \
        -w "%{http_code}" \
        -o /dev/null \
        "https://$host:$port/api" 2>/dev/null || echo "000")
    
    if [[ "$auth_status" == "204" ]]; then
        success "Authentication successful"
    else
        error "Authentication failed (HTTP $auth_status)"
        verbose "Response: $auth_response"
        return 1
    fi
}

test_secret_retrieval() {
    log "Testing secret retrieval with account '$TEST_ACCOUNT'..."
    
    # Extract credentials
    local username
    local password
    local host
    local port
    
    username=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.username}" | base64 -d)
    password=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.password}" | base64 -d)
    host=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.host}" | base64 -d)
    port=$(kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o jsonpath="{.data.port}" | base64 -d)
    
    # Create session first
    local cookie_jar="/tmp/wallix_test_cookies_$$"
    
    log "Creating WALLIX session..."
    local auth_status
    auth_status=$(curl -s -k --connect-timeout 10 --max-time 30 \
        -u "$username:$password" \
        -X POST \
        -c "$cookie_jar" \
        -w "%{http_code}" \
        -o /dev/null \
        "https://$host:$port/api" 2>/dev/null || echo "000")
    
    if [[ "$auth_status" != "204" ]]; then
        error "Failed to create session (HTTP $auth_status)"
        rm -f "$cookie_jar"
        return 1
    fi
    
    # Test secret retrieval
    local secret_response
    local secret_status
    
    secret_response=$(curl -s -k --connect-timeout 10 --max-time 30 \
        -b "$cookie_jar" \
        -H "Accept: application/json" \
        "https://$host:$port/api/targetpasswords/checkout/$TEST_ACCOUNT" 2>&1 || echo "ERROR")
    
    secret_status=$(curl -s -k --connect-timeout 10 --max-time 30 \
        -b "$cookie_jar" \
        -H "Accept: application/json" \
        -w "%{http_code}" \
        -o /dev/null \
        "https://$host:$port/api/targetpasswords/checkout/$TEST_ACCOUNT" 2>/dev/null || echo "000")
    
    # Cleanup
    rm -f "$cookie_jar"
    
    if [[ "$secret_status" == "200" ]]; then
        success "Secret retrieval successful for '$TEST_ACCOUNT'"
        verbose "Response: $secret_response"
    elif [[ "$secret_status" == "404" ]]; then
        warning "Account '$TEST_ACCOUNT' not found in WALLIX (this is OK for testing)"
    else
        error "Secret retrieval failed (HTTP $secret_status)"
        verbose "Response: $secret_response"
        return 1
    fi
}

generate_test_externalsecret() {
    log "Generating test ExternalSecret..."
    
    local test_secret_name="wallix-connection-test"
    
    cat << EOF > "/tmp/${test_secret_name}.yaml"
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: ${test_secret_name}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: wallix-test
    app.kubernetes.io/component: connection-test
  annotations:
    external-secrets.io/test: "true"
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: ${SECRETSTORE_NAME}
    kind: SecretStore
  
  target:
    name: ${test_secret_name}-secret
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        test-password: "{{ .password }}"
  
  data:
  - secretKey: password
    remoteRef:
      key: "${TEST_ACCOUNT}"
EOF
  
  refreshInterval: "1m"
EOF

    success "Test ExternalSecret generated: /tmp/${test_secret_name}.yaml"
    log "To test ExternalSecret functionality, run:"
    echo "  kubectl apply -f /tmp/${test_secret_name}.yaml"
    echo "  kubectl get externalsecret ${test_secret_name} -n ${NAMESPACE}"
    echo "  kubectl describe externalsecret ${test_secret_name} -n ${NAMESPACE}"
}

run_full_test() {
    log "Running full WALLIX Bastion connectivity test..."
    log "================================================"
    
    local failed_tests=0
    
    # Run all tests
    check_prerequisites || ((failed_tests++))
    check_namespace || ((failed_tests++))
    check_eso_installation || ((failed_tests++))
    check_credentials_secret || ((failed_tests++))
    check_secretstore || ((failed_tests++))
    test_wallix_connectivity || ((failed_tests++))
    test_secret_retrieval || ((failed_tests++))
    
    echo
    log "Test Summary"
    log "============"
    
    if [[ $failed_tests -eq 0 ]]; then
        success "All tests passed! WALLIX Bastion connectivity is properly configured."
        log "You can now create ExternalSecrets to sync secrets from WALLIX Bastion."
        echo
        generate_test_externalsecret
    else
        error "$failed_tests test(s) failed. Please check the configuration."
        echo
        log "Common troubleshooting steps:"
        echo "1. Verify WALLIX credentials in secret '$SECRET_NAME'"
        echo "2. Check network connectivity to WALLIX Bastion"
        echo "3. Ensure External Secrets Operator is running"
        echo "4. Review SecretStore configuration"
        echo "5. Check WALLIX API permissions for the user"
        return 1
    fi
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -s|--secret)
                SECRET_NAME="$2"
                shift 2
                ;;
            -t|--test-account)
                TEST_ACCOUNT="$2"
                shift 2
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    run_full_test
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi