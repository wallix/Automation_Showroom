#!/usr/bin/env bash

# ==============================================================================
# External Secrets Validation Script
# ==============================================================================
# This script validates ExternalSecrets and their synchronized secrets
# to ensure proper functionality with WALLIX Bastion.
# ==============================================================================

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-production}"
ALL_NAMESPACES="${ALL_NAMESPACES:-false}"
VERBOSE="${VERBOSE:-false}"
WATCH="${WATCH:-false}"
WATCH_INTERVAL="${WATCH_INTERVAL:-30}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
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
        echo -e "${CYAN}[VERBOSE]${NC} $*"
    fi
}

header() {
    echo -e "${MAGENTA}[SECTION]${NC} $*"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate ExternalSecrets and their synchronized secrets.

OPTIONS:
    -h, --help              Show this help
    -v, --verbose           Enable verbose output
    -n, --namespace NS      Target namespace (default: $NAMESPACE)
    -a, --all-namespaces    Check all namespaces
    -w, --watch             Watch mode (continuous monitoring)
    -i, --interval SEC      Watch interval in seconds (default: $WATCH_INTERVAL)
    
ENVIRONMENT VARIABLES:
    NAMESPACE               Target namespace
    ALL_NAMESPACES          Check all namespaces (true/false)
    VERBOSE                 Enable verbose mode (true/false)
    WATCH                   Enable watch mode (true/false)
    WATCH_INTERVAL          Watch interval in seconds

EXAMPLES:
    # Validate secrets in production namespace
    $0 -n production
    
    # Validate all ExternalSecrets across all namespaces
    $0 -a -v
    
    # Continuous monitoring with 60s interval
    $0 -w -i 60

EOF
}

get_namespace_option() {
    if [[ "$ALL_NAMESPACES" == "true" ]]; then
        echo "--all-namespaces"
    else
        echo "-n $NAMESPACE"
    fi
}

validate_externalsecret() {
    local name="$1"
    local namespace="$2"
    local issues=0
    
    verbose "Validating ExternalSecret '$name' in namespace '$namespace'"
    
    # Get ExternalSecret details
    local es_json
    es_json=$(kubectl get externalsecret "$name" -n "$namespace" -o json 2>/dev/null || echo "{}")
    
    if [[ "$es_json" == "{}" ]]; then
        error "ExternalSecret '$name' not found in namespace '$namespace'"
        return 1
    fi
    
    # Check status conditions
    local conditions
    conditions=$(echo "$es_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status' 2>/dev/null || echo "Unknown")
    
    if [[ "$conditions" == "True" ]]; then
        success "ExternalSecret '$name' is ready"
    elif [[ "$conditions" == "False" ]]; then
        error "ExternalSecret '$name' is not ready"
        local reason
        local message
        reason=$(echo "$es_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .reason' 2>/dev/null || echo "Unknown")
        message=$(echo "$es_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .message' 2>/dev/null || echo "Unknown")
        error "Reason: $reason"
        error "Message: $message"
        ((issues++))
    else
        warning "ExternalSecret '$name' status unknown"
        ((issues++))
    fi
    
    # Check refresh time
    local refresh_time
    refresh_time=$(echo "$es_json" | jq -r '.status.refreshTime // "never"' 2>/dev/null)
    verbose "Last refresh: $refresh_time"
    
    # Check target secret existence
    local target_name
    local target_namespace
    target_name=$(echo "$es_json" | jq -r '.spec.target.name // ""' 2>/dev/null)
    target_namespace=$(echo "$es_json" | jq -r '.spec.target.namespace // ""' 2>/dev/null)
    
    if [[ -z "$target_namespace" ]]; then
        target_namespace="$namespace"
    fi
    
    if [[ -n "$target_name" ]]; then
        if kubectl get secret "$target_name" -n "$target_namespace" >/dev/null 2>&1; then
            success "Target secret '$target_name' exists in namespace '$target_namespace'"
            
            # Validate secret content
            validate_secret_content "$target_name" "$target_namespace" "$es_json"
        else
            error "Target secret '$target_name' not found in namespace '$target_namespace'"
            ((issues++))
        fi
    else
        error "No target secret name specified"
        ((issues++))
    fi
    
    return $issues
}

validate_secret_content() {
    local secret_name="$1"
    local secret_namespace="$2"
    local es_json="$3"
    
    verbose "Validating content of secret '$secret_name'"
    
    # Get secret data
    local secret_json
    secret_json=$(kubectl get secret "$secret_name" -n "$secret_namespace" -o json 2>/dev/null || echo "{}")
    
    if [[ "$secret_json" == "{}" ]]; then
        error "Cannot retrieve secret '$secret_name'"
        return 1
    fi
    
    # Check expected keys from ExternalSecret spec
    local expected_keys
    expected_keys=$(echo "$es_json" | jq -r '.spec.data[]?.secretKey // empty' 2>/dev/null)
    
    local missing_keys=()
    local empty_keys=()
    
    while IFS= read -r key; do
        if [[ -n "$key" ]]; then
            if echo "$secret_json" | jq -e ".data.\"$key\"" >/dev/null 2>&1; then
                # Check if key value is empty
                local value
                value=$(echo "$secret_json" | jq -r ".data.\"$key\"" | base64 -d 2>/dev/null || echo "")
                if [[ -z "$value" ]]; then
                    empty_keys+=("$key")
                else
                    verbose "Key '$key' has content (${#value} characters)"
                fi
            else
                missing_keys+=("$key")
            fi
        fi
    done <<< "$expected_keys"
    
    # Report findings
    if [[ "${#missing_keys[@]}" -gt 0 ]]; then
        error "Missing keys in secret: ${missing_keys[*]}"
    fi
    
    if [[ "${#empty_keys[@]}" -gt 0 ]]; then
        warning "Empty keys in secret: ${empty_keys[*]}"
    fi
    
    if [[ "${#missing_keys[@]}" -eq 0 && "${#empty_keys[@]}" -eq 0 ]]; then
        success "Secret content validation passed"
    fi
    
    # Show secret metadata
    local creation_time
    local last_update
    creation_time=$(echo "$secret_json" | jq -r '.metadata.creationTimestamp // "unknown"')
    last_update=$(echo "$secret_json" | jq -r '.metadata.annotations."external-secrets.io/last-refresh" // "unknown"')
    
    verbose "Secret created: $creation_time"
    verbose "Last ESO update: $last_update"
}

validate_secretstore() {
    local name="$1"
    local namespace="$2"
    
    verbose "Validating SecretStore '$name' in namespace '$namespace'"
    
    # Get SecretStore status
    local ss_json
    ss_json=$(kubectl get secretstore "$name" -n "$namespace" -o json 2>/dev/null || echo "{}")
    
    if [[ "$ss_json" == "{}" ]]; then
        error "SecretStore '$name' not found in namespace '$namespace'"
        return 1
    fi
    
    # Check status
    local conditions
    conditions=$(echo "$ss_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status' 2>/dev/null || echo "Unknown")
    
    if [[ "$conditions" == "True" ]]; then
        success "SecretStore '$name' is ready"
    else
        error "SecretStore '$name' is not ready"
        local reason
        local message
        reason=$(echo "$ss_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .reason' 2>/dev/null || echo "Unknown")
        message=$(echo "$ss_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .message' 2>/dev/null || echo "Unknown")
        error "Reason: $reason"
        error "Message: $message"
        return 1
    fi
}

list_externalsecrets() {
    local ns_option
    ns_option=$(get_namespace_option)
    
    # Get all ExternalSecrets
    local externalsecrets
    externalsecrets=$(kubectl get externalsecrets $ns_option -o json 2>/dev/null || echo '{"items": []}')
    
    if [[ "$(echo "$externalsecrets" | jq '.items | length')" -eq 0 ]]; then
        warning "No ExternalSecrets found"
        return 0
    fi
    
    # Parse and return list
    echo "$externalsecrets" | jq -r '.items[] | "\(.metadata.name) \(.metadata.namespace)"'
}

list_secretstores() {
    local ns_option
    ns_option=$(get_namespace_option)
    
    # Get all SecretStores
    local secretstores
    secretstores=$(kubectl get secretstores $ns_option -o json 2>/dev/null || echo '{"items": []}')
    
    if [[ "$(echo "$secretstores" | jq '.items | length')" -eq 0 ]]; then
        warning "No SecretStores found"
        return 0
    fi
    
    # Parse and return list
    echo "$secretstores" | jq -r '.items[] | "\(.metadata.name) \(.metadata.namespace)"'
}

generate_summary_report() {
    local total_es="$1"
    local ready_es="$2"
    local total_ss="$3"
    local ready_ss="$4"
    
    header "Validation Summary"
    echo "=================="
    echo
    
    echo "ExternalSecrets:"
    echo "  Total: $total_es"
    echo "  Ready: $ready_es"
    echo "  Issues: $((total_es - ready_es))"
    echo
    
    echo "SecretStores:"
    echo "  Total: $total_ss"
    echo "  Ready: $ready_ss"
    echo "  Issues: $((total_ss - ready_ss))"
    echo
    
    if [[ $((total_es - ready_es + total_ss - ready_ss)) -eq 0 ]]; then
        success "All External Secrets are functioning correctly!"
    else
        error "Found issues with External Secrets configuration"
        echo
        log "Troubleshooting tips:"
        echo "1. Check External Secrets Operator logs:"
        echo "   kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets"
        echo "2. Verify WALLIX Bastion connectivity:"
        echo "   ./test-connection.sh"
        echo "3. Check SecretStore configuration:"
        echo "   kubectl describe secretstore <name> -n <namespace>"
        echo "4. Review ExternalSecret events:"
        echo "   kubectl describe externalsecret <name> -n <namespace>"
    fi
}

run_validation() {
    header "External Secrets Validation"
    log "============================="
    
    if [[ "$ALL_NAMESPACES" == "true" ]]; then
        log "Checking all namespaces..."
    else
        log "Checking namespace: $NAMESPACE"
    fi
    
    echo
    
    # Validate SecretStores first
    header "Validating SecretStores"
    local total_ss=0
    local ready_ss=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            
            ((total_ss++))
            if validate_secretstore "$name" "$namespace"; then
                ((ready_ss++))
            fi
            echo
        fi
    done <<< "$(list_secretstores)"
    
    # Validate ExternalSecrets
    header "Validating ExternalSecrets"
    local total_es=0
    local ready_es=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            
            ((total_es++))
            if validate_externalsecret "$name" "$namespace"; then
                ((ready_es++))
            fi
            echo
        fi
    done <<< "$(list_externalsecrets)"
    
    # Generate summary
    generate_summary_report "$total_es" "$ready_es" "$total_ss" "$ready_ss"
    
    # Return status
    if [[ $((total_es - ready_es + total_ss - ready_ss)) -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

watch_mode() {
    log "Starting watch mode (interval: ${WATCH_INTERVAL}s)"
    log "Press Ctrl+C to stop"
    echo
    
    while true; do
        clear
        echo "External Secrets Validation - $(date)"
        echo "=========================================="
        echo
        
        run_validation
        
        echo
        log "Next check in ${WATCH_INTERVAL} seconds..."
        sleep "$WATCH_INTERVAL"
    done
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
            -a|--all-namespaces)
                ALL_NAMESPACES="true"
                shift
                ;;
            -w|--watch)
                WATCH="true"
                shift
                ;;
            -i|--interval)
                WATCH_INTERVAL="$2"
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
    
    # Check prerequisites
    if ! command -v kubectl >/dev/null 2>&1; then
        error "kubectl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        error "jq is required but not installed"
        exit 1
    fi
    
    # Run validation
    if [[ "$WATCH" == "true" ]]; then
        watch_mode
    else
        run_validation
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi