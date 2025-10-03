#!/usr/bin/env bash

# ==============================================================================
# External Secrets Operator Cleanup Script
# ==============================================================================
# This script helps clean up External Secrets Operator resources
# for testing or troubleshooting purposes.
# ==============================================================================

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-production}"
ALL_NAMESPACES="${ALL_NAMESPACES:-false}"
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

header() {
    echo -e "${MAGENTA}[SECTION]${NC} $*"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Clean up External Secrets Operator resources.

COMMANDS:
    externalsecrets     Clean up ExternalSecrets only
    secretstores        Clean up SecretStores only
    secrets             Clean up generated secrets only
    all                 Clean up all ESO resources (default)
    test                Clean up test resources only

OPTIONS:
    -h, --help              Show this help
    -v, --verbose           Enable verbose output
    -n, --namespace NS      Target namespace (default: $NAMESPACE)
    -a, --all-namespaces    Clean all namespaces
    -d, --dry-run           Show what would be deleted without deleting
    -f, --force             Skip confirmation prompts
    
ENVIRONMENT VARIABLES:
    NAMESPACE               Target namespace
    ALL_NAMESPACES          Clean all namespaces (true/false)
    DRY_RUN                 Dry run mode (true/false)
    FORCE                   Skip confirmations (true/false)
    VERBOSE                 Enable verbose mode (true/false)

EXAMPLES:
    # Dry run cleanup in production namespace
    $0 -d -n production
    
    # Force cleanup of all ExternalSecrets across all namespaces
    $0 -f -a externalsecrets
    
    # Clean up test resources only
    $0 test

EOF
}

confirm_action() {
    local action="$1"
    
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo
    warning "About to $action"
    echo -n "Are you sure? (y/N): "
    read -r response
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log "Operation cancelled"
            return 1
            ;;
    esac
}

get_namespace_option() {
    if [[ "$ALL_NAMESPACES" == "true" ]]; then
        echo "--all-namespaces"
    else
        echo "-n $NAMESPACE"
    fi
}

execute_command() {
    local cmd="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would execute: $cmd"
        return 0
    fi
    
    verbose "Executing: $cmd"
    if eval "$cmd"; then
        success "$description"
    else
        error "Failed: $description"
        return 1
    fi
}

cleanup_externalsecrets() {
    header "Cleaning up ExternalSecrets"
    
    local ns_option
    ns_option=$(get_namespace_option)
    
    # List ExternalSecrets
    local externalsecrets
    externalsecrets=$(kubectl get externalsecrets $ns_option --no-headers 2>/dev/null | awk '{print $1 " " $2}' || true)
    
    if [[ -z "$externalsecrets" ]]; then
        log "No ExternalSecrets found"
        return 0
    fi
    
    log "Found ExternalSecrets:"
    echo "$externalsecrets" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            echo "  - $name (namespace: $namespace)"
        fi
    done
    
    if ! confirm_action "delete these ExternalSecrets"; then
        return 1
    fi
    
    # Delete ExternalSecrets
    echo "$externalsecrets" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            
            execute_command \
                "kubectl delete externalsecret '$name' -n '$namespace'" \
                "Deleted ExternalSecret '$name' in namespace '$namespace'"
        fi
    done
}

cleanup_secretstores() {
    header "Cleaning up SecretStores"
    
    local ns_option
    ns_option=$(get_namespace_option)
    
    # List SecretStores
    local secretstores
    secretstores=$(kubectl get secretstores $ns_option --no-headers 2>/dev/null | awk '{print $1 " " $2}' || true)
    
    if [[ -z "$secretstores" ]]; then
        log "No SecretStores found"
        return 0
    fi
    
    log "Found SecretStores:"
    echo "$secretstores" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            echo "  - $name (namespace: $namespace)"
        fi
    done
    
    if ! confirm_action "delete these SecretStores"; then
        return 1
    fi
    
    # Delete SecretStores
    echo "$secretstores" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            
            execute_command \
                "kubectl delete secretstore '$name' -n '$namespace'" \
                "Deleted SecretStore '$name' in namespace '$namespace'"
        fi
    done
}

cleanup_secrets() {
    header "Cleaning up ESO-generated secrets"
    
    local ns_option
    ns_option=$(get_namespace_option)
    
    # Find secrets managed by External Secrets Operator
    local eso_secrets
    eso_secrets=$(kubectl get secrets $ns_option -o json 2>/dev/null | \
        jq -r '.items[] | select(.metadata.annotations."external-secrets.io/last-refresh" != null) | "\(.metadata.name) \(.metadata.namespace)"' || true)
    
    if [[ -z "$eso_secrets" ]]; then
        log "No ESO-managed secrets found"
        return 0
    fi
    
    log "Found ESO-managed secrets:"
    echo "$eso_secrets" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            echo "  - $name (namespace: $namespace)"
        fi
    done
    
    if ! confirm_action "delete these ESO-managed secrets"; then
        return 1
    fi
    
    # Delete secrets
    echo "$eso_secrets" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | cut -d' ' -f1)
            namespace=$(echo "$line" | cut -d' ' -f2)
            
            execute_command \
                "kubectl delete secret '$name' -n '$namespace'" \
                "Deleted secret '$name' in namespace '$namespace'"
        fi
    done
}

cleanup_test_resources() {
    header "Cleaning up test resources"
    
    local ns_option
    ns_option=$(get_namespace_option)
    
    # Clean up resources with test labels/annotations
    local test_resources
    test_resources=$(kubectl get externalsecrets,secrets $ns_option -o json 2>/dev/null | \
        jq -r '.items[] | select(.metadata.annotations."external-secrets.io/test" == "true" or .metadata.labels."app.kubernetes.io/component" == "connection-test") | "\(.kind) \(.metadata.name) \(.metadata.namespace)"' || true)
    
    if [[ -z "$test_resources" ]]; then
        log "No test resources found"
        return 0
    fi
    
    log "Found test resources:"
    echo "$test_resources" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local kind name namespace
            kind=$(echo "$line" | cut -d' ' -f1)
            name=$(echo "$line" | cut -d' ' -f2)
            namespace=$(echo "$line" | cut -d' ' -f3)
            echo "  - $kind/$name (namespace: $namespace)"
        fi
    done
    
    if ! confirm_action "delete these test resources"; then
        return 1
    fi
    
    # Delete test resources
    echo "$test_resources" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local kind name namespace
            kind=$(echo "$line" | cut -d' ' -f1)
            name=$(echo "$line" | cut -d' ' -f2)
            namespace=$(echo "$line" | cut -d' ' -f3)
            
            execute_command \
                "kubectl delete $kind '$name' -n '$namespace'" \
                "Deleted $kind '$name' in namespace '$namespace'"
        fi
    done
    
    # Clean up temporary files
    if [[ -f "/tmp/wallix-connection-test.yaml" ]]; then
        execute_command \
            "rm -f /tmp/wallix-connection-test.yaml" \
            "Removed temporary test file"
    fi
}

cleanup_all() {
    header "Cleaning up all ESO resources"
    
    cleanup_externalsecrets
    echo
    cleanup_secrets
    echo
    cleanup_secretstores
}

main() {
    local command="all"
    
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
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            externalsecrets|secretstores|secrets|all|test)
                command="$1"
                shift
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
    
    # Show configuration
    log "Cleanup Configuration:"
    log "  Command: $command"
    if [[ "$ALL_NAMESPACES" == "true" ]]; then
        log "  Scope: All namespaces"
    else
        log "  Namespace: $NAMESPACE"
    fi
    log "  Dry run: $DRY_RUN"
    log "  Force: $FORCE"
    echo
    
    # Execute command
    case "$command" in
        externalsecrets)
            cleanup_externalsecrets
            ;;
        secretstores)
            cleanup_secretstores
            ;;
        secrets)
            cleanup_secrets
            ;;
        test)
            cleanup_test_resources
            ;;
        all)
            cleanup_all
            ;;
        *)
            error "Unknown command: $command"
            exit 1
            ;;
    esac
    
    echo
    success "Cleanup completed!"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi