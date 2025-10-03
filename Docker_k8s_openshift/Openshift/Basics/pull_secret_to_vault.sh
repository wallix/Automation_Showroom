#!/usr/bin/env bash

# ==============================================================================
# WALLIX to OpenShift Secret Management Script
# ==============================================================================
# This script retrieves secrets from WALLIX Bastion API and creates them 
# as OpenShift secrets in a specified namespace.
#
# Prerequisites:
# - oc CLI tool installed and configured
# - curl and jq installed
# - Valid WALLIX Bastion credentials
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Configuration Variables
# ==============================================================================

# WALLIX Bastion Configuration
WALLIX_HOST="${WALLIX_HOST:-192.168.1.75}"
WALLIX_PORT="${WALLIX_PORT:-443}"
WALLIX_API_BASE="https://${WALLIX_HOST}:${WALLIX_PORT}/api"
WALLIX_USERNAME="${WALLIX_USERNAME:-admin}"
WALLIX_PASSWORD="${WALLIX_PASSWORD:-}"

# OpenShift Configuration
OPENSHIFT_NAMESPACE="${OPENSHIFT_NAMESPACE:-default}"
SECRET_NAME_PREFIX="${SECRET_NAME_PREFIX:-wallix}"

# Script Configuration
VERBOSE="${VERBOSE:-false}"
DRY_RUN="${DRY_RUN:-false}"
COOKIE_FILE="/tmp/.wallix_session_$$"

# ==============================================================================
# Utility Functions
# ==============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        log "VERBOSE: $*"
    fi
}

error() {
    log "ERROR: $*" >&2
    exit 1
}

cleanup() {
    log_verbose "Cleaning up session files..."
    [[ -f "$COOKIE_FILE" ]] && rm -f "$COOKIE_FILE"
}

# Setup cleanup trap
trap cleanup EXIT

prompt_for_password() {
    if [[ -n "${WALLIX_PASSWORD:-}" ]]; then
        log_verbose "Using password from environment variable"
        return 0
    fi
    
    # Check if we're in a terminal
    if [[ ! -t 0 ]]; then
        error "Password required but not running in a terminal. Please set WALLIX_PASSWORD environment variable"
    fi
    
    log "WALLIX password not provided in environment"
    echo -n "Enter WALLIX password for user '$WALLIX_USERNAME': " >&2
    
    # Use read with -s flag to hide password input
    read -r -s WALLIX_PASSWORD
    echo >&2  # Add newline after hidden input
    
    if [[ -z "$WALLIX_PASSWORD" ]]; then
        error "Password cannot be empty"
    fi
    
    log_verbose "Password provided via prompt"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS] ACCOUNT_SPECIFIER

Retrieve a secret from WALLIX Bastion and create it as an OpenShift secret.

ACCOUNT_SPECIFIER format: account@target@domain (e.g., root@local@debian)

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -d, --dry-run           Show what would be done without executing
    -n, --namespace NS      OpenShift namespace (default: $OPENSHIFT_NAMESPACE)
    -p, --prefix PREFIX     Secret name prefix (default: $SECRET_NAME_PREFIX)
    
ENVIRONMENT VARIABLES:
    WALLIX_HOST             WALLIX Bastion hostname/IP (default: $WALLIX_HOST)
    WALLIX_PORT             WALLIX Bastion port (default: $WALLIX_PORT)
    WALLIX_USERNAME         WALLIX username (default: $WALLIX_USERNAME)
    WALLIX_PASSWORD         WALLIX password (optional - will prompt if not set)
    OPENSHIFT_NAMESPACE     Target namespace (default: $OPENSHIFT_NAMESPACE)
    VERBOSE                 Enable verbose mode (default: $VERBOSE)
    DRY_RUN                 Enable dry-run mode (default: $DRY_RUN)

EXAMPLES:
    # Basic usage with password prompt
    $0 root@local@debian
    
    # Basic usage with environment variable
    WALLIX_PASSWORD=mypass $0 root@local@debian
    
    # With custom namespace and verbose output
    WALLIX_PASSWORD=mypass $0 -v -n production admin@webserver@corp
    
    # Dry run to see what would happen
    $0 -d postgres@dbserver@local

EOF
}

# ==============================================================================
# WALLIX API Functions
# ==============================================================================

wallix_authenticate() {
    log "Authenticating with WALLIX Bastion at $WALLIX_HOST..."
    
    # Prompt for password if not provided
    prompt_for_password
    
    # Create session with POST to /api using Basic Auth
    local response
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        --insecure \
        --user "$WALLIX_USERNAME:$WALLIX_PASSWORD" \
        --cookie-jar "$COOKIE_FILE" \
        -X POST \
        "$WALLIX_API_BASE" \
        2>/dev/null)
    
    local body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')
    local status=$(echo "$response" | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
    
    log_verbose "Authentication response status: $status"
    
    if [[ "$status" != "204" ]]; then
        error "Authentication failed with status $status. Response: $body"
    fi
    
    log "Successfully authenticated with WALLIX Bastion"
}

wallix_get_target_password() {
    local account_specifier="$1"
    
    log "Retrieving password for account specifier '$account_specifier'..."
    
    # Validate format: account@target@domain
    if [[ ! "$account_specifier" =~ ^[^@]+@[^@]+@[^@]+$ ]]; then
        error "Invalid account specifier format. Expected: account@target@domain (e.g., root@local@debian)"
    fi
    
    # Use the WALLIX API endpoint: /api/targetpasswords/checkout/{account@target@domain}
    local endpoint="/targetpasswords/checkout/${account_specifier}"
    local response
    
    log_verbose "Using endpoint: $WALLIX_API_BASE$endpoint"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        --insecure \
        --cookie "$COOKIE_FILE" \
        -H "Accept: application/json" \
        -X GET \
        "$WALLIX_API_BASE$endpoint" \
        2>/dev/null)
    
    local body
    local status
    body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')
    status=$(echo "$response" | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
    
    log_verbose "Password retrieval response status: $status"
    log_verbose "Response body: $body"
    
    if [[ "$status" != "200" ]]; then
        error "Failed to retrieve password for '$account_specifier'. Status: $status, Response: $body"
    fi
    
    # Extract password from JSON response
    # The response format may vary, common fields: password, secret, value
    local password
    if command -v jq >/dev/null 2>&1; then
        password=$(echo "$body" | jq -r '.password // .secret // .value // empty' 2>/dev/null)
        if [[ -z "$password" || "$password" == "null" ]]; then
            password=$(echo "$body" | jq -r 'if type=="string" then . else empty end' 2>/dev/null)
        fi
    else
        # Fallback parsing without jq
        password=$(echo "$body" | grep -o '"password":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "$body")
    fi
    
    if [[ -z "$password" || "$password" == "null" ]]; then
        error "Could not extract password from response: $body"
    fi
    
    log "Successfully retrieved password for '$account_specifier'"
    echo "$password"
}

wallix_logout() {
    log_verbose "Logging out from WALLIX Bastion..."
    
    curl -s \
        --insecure \
        --cookie "$COOKIE_FILE" \
        -X DELETE \
        "$WALLIX_API_BASE" \
        >/dev/null 2>&1 || true
        
    log_verbose "Logout completed"
}

# ==============================================================================
# OpenShift Functions
# ==============================================================================

openshift_create_secret() {
    local secret_name="$1"
    local secret_key="$2"
    local secret_value="$3"
    local namespace="$4"
    
    log "Creating OpenShift secret '$secret_name' in namespace '$namespace'..."
    
    # Check if oc command is available
    if ! command -v oc >/dev/null 2>&1; then
        error "OpenShift CLI 'oc' is not installed or not in PATH"
    fi
    
    # Check if we're logged into OpenShift
    if ! oc whoami >/dev/null 2>&1; then
        error "Not logged into OpenShift. Please run 'oc login' first"
    fi
    
    # Check if namespace exists
    if ! oc get namespace "$namespace" >/dev/null 2>&1; then
        log "Namespace '$namespace' does not exist. Creating it..."
        if [[ "$DRY_RUN" == "false" ]]; then
            oc create namespace "$namespace"
        else
            log "DRY-RUN: Would create namespace '$namespace'"
        fi
    fi
    
    # Delete existing secret if it exists
    if oc get secret "$secret_name" -n "$namespace" >/dev/null 2>&1; then
        log "Secret '$secret_name' already exists. Deleting it..."
        if [[ "$DRY_RUN" == "false" ]]; then
            oc delete secret "$secret_name" -n "$namespace"
        else
            log "DRY-RUN: Would delete existing secret '$secret_name'"
        fi
    fi
    
    # Create the secret
    if [[ "$DRY_RUN" == "false" ]]; then
        oc create secret generic "$secret_name" \
            --from-literal="$secret_key=$secret_value" \
            --namespace "$namespace"
        log "Successfully created secret '$secret_name' in namespace '$namespace'"
    else
        log "DRY-RUN: Would create secret '$secret_name' with key '$secret_key' in namespace '$namespace'"
    fi
}

# ==============================================================================
# Main Function
# ==============================================================================

main() {
    local account_specifier=""
    
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
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -n|--namespace)
                OPENSHIFT_NAMESPACE="$2"
                shift 2
                ;;
            -p|--prefix)
                SECRET_NAME_PREFIX="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                if [[ -z "$account_specifier" ]]; then
                    account_specifier="$1"
                else
                    error "Too many arguments. Expected: ACCOUNT_SPECIFIER (format: account@target@domain)"
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$account_specifier" ]]; then
        error "ACCOUNT_SPECIFIER is required (format: account@target@domain)"
    fi
    
    log "Starting WALLIX to OpenShift secret transfer..."
    log "Account specifier: $account_specifier"
    log "Namespace: $OPENSHIFT_NAMESPACE, Dry-run: $DRY_RUN"
    
    # Authenticate with WALLIX
    wallix_authenticate
    
    # Retrieve the password
    local password
    password=$(wallix_get_target_password "$account_specifier")
    
    # Logout from WALLIX
    wallix_logout
    
    # Create OpenShift secret
    # Extract components from account_specifier for secret name
    local account_part=$(echo "$account_specifier" | cut -d'@' -f1)
    local target_part=$(echo "$account_specifier" | cut -d'@' -f2)
    local domain_part=$(echo "$account_specifier" | cut -d'@' -f3)
    
    local secret_name="${SECRET_NAME_PREFIX}-${account_part}-${target_part}-${domain_part}"
    local secret_key="password"
    
    # Sanitize secret name (OpenShift secret names must be DNS-1123 compliant)
    secret_name=$(echo "$secret_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    openshift_create_secret "$secret_name" "$secret_key" "$password" "$OPENSHIFT_NAMESPACE"
    
    log "Secret transfer completed successfully!"
    log "Account specifier: $account_specifier"
    log "Secret name: $secret_name"
    log "Secret key: $secret_key"
    log "Namespace: $OPENSHIFT_NAMESPACE"
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
