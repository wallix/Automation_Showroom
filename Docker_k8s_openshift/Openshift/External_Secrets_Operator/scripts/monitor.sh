#!/usr/bin/env bash

# ==============================================================================
# External Secrets Operator Monitoring Script
# ==============================================================================
# This script provides monitoring and alerting for External Secrets Operator
# resources and their synchronization status.
# ==============================================================================

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-production}"
ALL_NAMESPACES="${ALL_NAMESPACES:-false}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
ALERT_THRESHOLD="${ALERT_THRESHOLD:-5}"
LOG_FILE="${LOG_FILE:-/tmp/eso-monitor.log}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $*" | tee -a "$LOG_FILE"
}

success() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[$timestamp]${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[$timestamp]${NC} $*" | tee -a "$LOG_FILE"
}

verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${CYAN}[$timestamp]${NC} $*" | tee -a "$LOG_FILE"
    fi
}

header() {
    echo -e "${MAGENTA}[MONITOR]${NC} $*" | tee -a "$LOG_FILE"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Monitor External Secrets Operator resources and their status.

OPTIONS:
    -h, --help              Show this help
    -v, --verbose           Enable verbose output
    -n, --namespace NS      Target namespace (default: $NAMESPACE)
    -a, --all-namespaces    Monitor all namespaces
    -i, --interval SEC      Check interval in seconds (default: $CHECK_INTERVAL)
    -t, --threshold NUM     Alert threshold in minutes (default: $ALERT_THRESHOLD)
    -l, --log-file FILE     Log file path (default: $LOG_FILE)
    -w, --webhook URL       Webhook URL for alerts
    
ENVIRONMENT VARIABLES:
    NAMESPACE               Target namespace
    ALL_NAMESPACES          Monitor all namespaces (true/false)
    CHECK_INTERVAL          Check interval in seconds
    ALERT_THRESHOLD         Alert threshold in minutes
    LOG_FILE                Log file path
    WEBHOOK_URL             Webhook URL for alerts
    VERBOSE                 Enable verbose mode (true/false)

EXAMPLES:
    # Basic monitoring
    $0
    
    # Monitor all namespaces with 30s interval
    $0 -a -i 30
    
    # Monitor with webhook alerts
    $0 -w "https://hooks.slack.com/services/..."

EOF
}

send_webhook_alert() {
    local title="$1"
    local message="$2"
    local severity="${3:-warning}"
    
    if [[ -z "$WEBHOOK_URL" ]]; then
        return 0
    fi
    
    local color="#ffaa00"  # Orange for warning
    case "$severity" in
        error)
            color="#ff0000"  # Red
            ;;
        success)
            color="#00ff00"  # Green
            ;;
        info)
            color="#0000ff"  # Blue
            ;;
    esac
    
    local payload
    payload=$(cat << EOF
{
  "attachments": [
    {
      "color": "$color",
      "title": "ESO Monitor: $title",
      "text": "$message",
      "ts": $(date +%s)
    }
  ]
}
EOF
)
    
    verbose "Sending webhook alert: $title"
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" >/dev/null 2>&1 || {
        error "Failed to send webhook alert"
    }
}

get_namespace_option() {
    if [[ "$ALL_NAMESPACES" == "true" ]]; then
        echo "--all-namespaces"
    else
        echo "-n $NAMESPACE"
    fi
}

check_eso_health() {
    verbose "Checking External Secrets Operator health..."
    
    # Check ESO pods
    local eso_pods
    eso_pods=$(kubectl get pods -n external-secrets-system -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | wc -l)
    
    if [[ "$eso_pods" -eq 0 ]]; then
        error "No External Secrets Operator pods found"
        send_webhook_alert "ESO Down" "No External Secrets Operator pods found" "error"
        return 1
    fi
    
    local running_pods
    running_pods=$(kubectl get pods -n external-secrets-system -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep Running | wc -l)
    
    if [[ "$running_pods" -eq 0 ]]; then
        error "No External Secrets Operator pods are running"
        send_webhook_alert "ESO Unhealthy" "No ESO pods are running ($eso_pods total)" "error"
        return 1
    elif [[ "$running_pods" -lt "$eso_pods" ]]; then
        warning "Some ESO pods are not running ($running_pods/$eso_pods)"
        send_webhook_alert "ESO Degraded" "Some ESO pods not running ($running_pods/$eso_pods)" "warning"
    else
        verbose "ESO is healthy ($running_pods/$eso_pods pods running)"
    fi
    
    return 0
}

check_externalsecret_status() {
    local name="$1"
    local namespace="$2"
    
    verbose "Checking ExternalSecret '$name' in namespace '$namespace'"
    
    # Get ExternalSecret status
    local es_json
    es_json=$(kubectl get externalsecret "$name" -n "$namespace" -o json 2>/dev/null || echo "{}")    
    if [[ "$es_json" == "{}" ]]; then
        error "ExternalSecret '$name' not found"
        return 1
    fi
    
    # Check status conditions
    local ready_status
    local ready_reason
    local ready_message
    
    ready_status=$(echo "$es_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status' 2>/dev/null || echo "Unknown")
    ready_reason=$(echo "$es_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .reason' 2>/dev/null || echo "Unknown")
    ready_message=$(echo "$es_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .message' 2>/dev/null || echo "Unknown")
    
    # Check refresh time
    local refresh_time
    local last_refresh_timestamp
    
    refresh_time=$(echo "$es_json" | jq -r '.status.refreshTime // "never"' 2>/dev/null)
    
    if [[ "$refresh_time" != "never" ]]; then
        last_refresh_timestamp=$(date -d "$refresh_time" +%s 2>/dev/null || echo "0")
        local current_timestamp
        current_timestamp=$(date +%s)
        local time_diff
        time_diff=$(( (current_timestamp - last_refresh_timestamp) / 60 ))
        
        if [[ "$time_diff" -gt "$ALERT_THRESHOLD" ]]; then
            warning "ExternalSecret '$name' not refreshed for $time_diff minutes"
            send_webhook_alert "Stale ExternalSecret" "ExternalSecret '$name' in '$namespace' not refreshed for $time_diff minutes" "warning"
        else
            verbose "ExternalSecret '$name' last refreshed $time_diff minutes ago"
        fi
    else
        warning "ExternalSecret '$name' has never been refreshed"
        send_webhook_alert "Never Refreshed" "ExternalSecret '$name' in '$namespace' has never been refreshed" "warning"
    fi
    
    # Check overall status
    case "$ready_status" in
        "True")
            verbose "ExternalSecret '$name' is ready"
            return 0
            ;;
        "False")
            error "ExternalSecret '$name' is not ready: $ready_reason - $ready_message"
            send_webhook_alert "ExternalSecret Failed" "ExternalSecret '$name' in '$namespace' failed: $ready_reason" "error"
            return 1
            ;;
        *)
            warning "ExternalSecret '$name' status unknown"
            send_webhook_alert "ExternalSecret Unknown" "ExternalSecret '$name' in '$namespace' has unknown status" "warning"
            return 1
            ;;
    esac
}

check_secretstore_status() {
    local name="$1"
    local namespace="$2"
    
    verbose "Checking SecretStore '$name' in namespace '$namespace'"
    
    # Get SecretStore status
    local ss_json
    ss_json=$(kubectl get secretstore "$name" -n "$namespace" -o json 2>/dev/null || echo "{}")
    
    if [[ "$ss_json" == "{}" ]]; then
        error "SecretStore '$name' not found"
        return 1
    fi
    
    # Check status conditions
    local ready_status
    local ready_reason
    local ready_message
    
    ready_status=$(echo "$ss_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status' 2>/dev/null || echo "Unknown")
    ready_reason=$(echo "$ss_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .reason' 2>/dev/null || echo "Unknown")
    ready_message=$(echo "$ss_json" | jq -r '.status.conditions[]? | select(.type=="Ready") | .message' 2>/dev/null || echo "Unknown")
    
    case "$ready_status" in
        "True")
            verbose "SecretStore '$name' is ready"
            return 0
            ;;
        "False")
            error "SecretStore '$name' is not ready: $ready_reason - $ready_message"
            send_webhook_alert "SecretStore Failed" "SecretStore '$name' in '$namespace' failed: $ready_reason" "error"
            return 1
            ;;
        *)
            warning "SecretStore '$name' status unknown"
            send_webhook_alert "SecretStore Unknown" "SecretStore '$name' in '$namespace' has unknown status" "warning"
            return 1
            ;;
    esac
}

monitor_resources() {
    local ns_option
    ns_option=$(get_namespace_option)
    
    local total_issues=0
    local total_externalsecrets=0
    local total_secretstores=0
    
    # Monitor SecretStores
    verbose "Monitoring SecretStores..."
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | awk '{print $1}')
            namespace=$(echo "$line" | awk '{print $2}')
            
            ((total_secretstores++))
            if ! check_secretstore_status "$name" "$namespace"; then
                ((total_issues++))
            fi
        fi
    done <<< "$(kubectl get secretstores $ns_option --no-headers 2>/dev/null | awk '{print $1 " " $2}' || true)"
    
    # Monitor ExternalSecrets
    verbose "Monitoring ExternalSecrets..."
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name namespace
            name=$(echo "$line" | awk '{print $1}')
            namespace=$(echo "$line" | awk '{print $2}')
            
            ((total_externalsecrets++))
            if ! check_externalsecret_status "$name" "$namespace"; then
                ((total_issues++))
            fi
        fi
    done <<< "$(kubectl get externalsecrets $ns_option --no-headers 2>/dev/null | awk '{print $1 " " $2}' || true)"
    
    # Summary
    if [[ "$total_issues" -eq 0 ]]; then
        success "All resources healthy (ExternalSecrets: $total_externalsecrets, SecretStores: $total_secretstores)"
    else
        error "Found $total_issues issues across $total_externalsecrets ExternalSecrets and $total_secretstores SecretStores"
    fi
    
    return $total_issues
}

monitor_loop() {
    header "Starting External Secrets Operator monitoring"
    log "Monitoring configuration:"
    log "  Namespaces: $(if [[ "$ALL_NAMESPACES" == "true" ]]; then echo "all"; else echo "$NAMESPACE"; fi)"
    log "  Check interval: ${CHECK_INTERVAL}s"
    log "  Alert threshold: ${ALERT_THRESHOLD}m"
    log "  Log file: $LOG_FILE"
    log "  Webhook: $(if [[ -n "$WEBHOOK_URL" ]]; then echo "enabled"; else echo "disabled"; fi)"
    log "  Press Ctrl+C to stop"
    echo
    
    # Initialize log file
    echo "External Secrets Operator Monitor - Started $(date)" > "$LOG_FILE"
    
    local consecutive_failures=0
    
    while true; do
        local start_time
        start_time=$(date +%s)
        
        # Check ESO health first
        if ! check_eso_health; then
            ((consecutive_failures++))
            if [[ "$consecutive_failures" -ge 3 ]]; then
                error "ESO has been unhealthy for 3 consecutive checks"
                send_webhook_alert "ESO Critical" "External Secrets Operator has been unhealthy for 3 consecutive checks" "error"
            fi
        else
            if [[ "$consecutive_failures" -gt 0 ]]; then
                success "ESO health recovered after $consecutive_failures failed checks"
                send_webhook_alert "ESO Recovered" "External Secrets Operator health recovered" "success"
                consecutive_failures=0
            fi
            
            # Monitor resources only if ESO is healthy
            monitor_resources
        fi
        
        local end_time
        end_time=$(date +%s)
        local check_duration
        check_duration=$((end_time - start_time))
        
        verbose "Check completed in ${check_duration}s"
        
        # Calculate sleep time
        local sleep_time
        sleep_time=$((CHECK_INTERVAL - check_duration))
        if [[ "$sleep_time" -lt 1 ]]; then
            sleep_time=1
        fi
        
        verbose "Next check in ${sleep_time}s"
        sleep "$sleep_time"
    done
}

generate_health_report() {
    header "External Secrets Operator Health Report"
    echo "========================================"
    echo
    
    # ESO pods status
    echo "External Secrets Operator Pods:"
    kubectl get pods -n external-secrets-system -l app.kubernetes.io/name=external-secrets 2>/dev/null || echo "  Error: Unable to get ESO pods"
    echo
    
    # SecretStores status
    echo "SecretStores:"
    local ns_option
    ns_option=$(get_namespace_option)
    kubectl get secretstores $ns_option 2>/dev/null || echo "  No SecretStores found"
    echo
    
    # ExternalSecrets status
    echo "ExternalSecrets:"
    kubectl get externalsecrets $ns_option 2>/dev/null || echo "  No ExternalSecrets found"
    echo
    
    # Recent events
    echo "Recent Events:"
    kubectl get events $ns_option --sort-by='.firstTimestamp' 2>/dev/null | \
        grep -i "externalsecret\\|secretstore" | tail -10 || echo "  No recent events found"
}

main() {
    local action="monitor"
    
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
            -i|--interval)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            -t|--threshold)
                ALERT_THRESHOLD="$2"
                shift 2
                ;;
            -l|--log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -w|--webhook)
                WEBHOOK_URL="$2"
                shift 2
                ;;
            report)
                action="report"
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
    
    # Execute action
    case "$action" in
        monitor)
            monitor_loop
            ;;
        report)
            generate_health_report
            ;;
        *)
            error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi