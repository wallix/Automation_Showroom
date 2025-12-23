#!/bin/bash
# WALLIX OpenShift Simple Integration - Lab Deployment Script
# This script deploys the simple integration on your OpenShift/Kubernetes lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="${SCRIPT_DIR}/../examples"
CONFIG_FILE="${SCRIPT_DIR}/wallix-config.env"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  WALLIX Simple Integration Deployment for OpenShift  ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to print messages
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check for kubectl or oc
check_cluster_access() {
    print_info "Checking cluster access..."
    
    if command -v oc &> /dev/null; then
        CLI_TOOL="oc"
        print_success "Found OpenShift CLI (oc)"
    elif command -v kubectl &> /dev/null; then
        CLI_TOOL="kubectl"
        print_success "Found Kubernetes CLI (kubectl)"
    else
        print_error "Neither 'oc' nor 'kubectl' found in PATH"
        echo ""
        echo "Please install one of:"
        echo "  - OpenShift CLI: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html"
        echo "  - Kubernetes CLI: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    # Test cluster connection
    if ! $CLI_TOOL cluster-info &> /dev/null; then
        print_error "Cannot connect to cluster"
        echo ""
        echo "Please ensure you're logged in:"
        echo "  OpenShift: oc login <cluster-url>"
        echo "  Kubernetes: kubectl config use-context <context>"
        exit 1
    fi
    
    CURRENT_CONTEXT=$($CLI_TOOL config current-context 2>/dev/null || echo "unknown")
    print_success "Connected to cluster: $CURRENT_CONTEXT"
}

# Load configuration
load_config() {
    print_info "Loading configuration..."
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "Configuration file not found: $CONFIG_FILE"
        echo ""
        echo "Creating configuration file from template..."
        cp "${CONFIG_FILE}.example" "$CONFIG_FILE"
        
        print_error "Please edit $CONFIG_FILE with your WALLIX Bastion details"
        echo ""
        echo "Required values:"
        echo "  - BASTION_URL: Your WALLIX Bastion URL (e.g., https://bastion.example.com)"
        echo "  - API_USER: WALLIX API username (e.g., admin)"
        echo "  - API_KEY: Your WALLIX API key"
        echo "  - SECRET_KEY: Secret to retrieve (format: account@target@domain)"
        echo ""
        echo "After editing, run this script again."
        exit 1
    fi
    
    # Source the config file
    source "$CONFIG_FILE"
    
    # Validate required variables
    if [ -z "$BASTION_URL" ] || [ "$BASTION_URL" == "https://bastion.example.com" ]; then
        print_error "BASTION_URL not configured in $CONFIG_FILE"
        exit 1
    fi
    
    if [ -z "$API_KEY" ] || [ "$API_KEY" == "YOUR_API_KEY_HERE" ]; then
        print_error "API_KEY not configured in $CONFIG_FILE"
        exit 1
    fi
    
    if [ -z "$SECRET_KEY" ] || [ "$SECRET_KEY" == "admin@server@domain.local" ]; then
        print_error "SECRET_KEY not configured in $CONFIG_FILE"
        exit 1
    fi
    
    print_success "Configuration loaded successfully"
    echo "  BASTION_URL: $BASTION_URL"
    echo "  API_USER: $API_USER"
    echo "  SECRET_KEY: $SECRET_KEY"
}

# Test WALLIX API connectivity
test_wallix_api() {
    print_info "Testing WALLIX Bastion API connectivity..."
    
    # Test basic connectivity
    if ! curl -k -s -f --connect-timeout 5 "${BASTION_URL}" > /dev/null 2>&1; then
        print_error "Cannot reach WALLIX Bastion at $BASTION_URL"
        echo ""
        echo "Please check:"
        echo "  - Bastion URL is correct"
        echo "  - Network connectivity from this machine"
        echo "  - Firewall/proxy settings"
        exit 1
    fi
    
    print_success "WALLIX Bastion is reachable"
    
    # Test API credentials
    print_info "Testing API credentials..."
    RESPONSE=$(curl -k -s -w "\n%{http_code}" \
        -H "X-Auth-User: ${API_USER}" \
        -H "X-Auth-Key: ${API_KEY}" \
        "${BASTION_URL}/api/targetpasswords/checkout/${SECRET_KEY}")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" == "200" ]; then
        print_success "API credentials are valid"
        PASSWORD=$(echo "$BODY" | jq -r '.password // empty' 2>/dev/null)
        if [ -n "$PASSWORD" ]; then
            print_success "Successfully retrieved secret from WALLIX"
        else
            print_warning "API call successful but no password returned"
        fi
    elif [ "$HTTP_CODE" == "401" ]; then
        print_error "API authentication failed (401 Unauthorized)"
        echo "  Please check API_USER and API_KEY in $CONFIG_FILE"
        exit 1
    elif [ "$HTTP_CODE" == "404" ]; then
        print_error "Secret not found (404 Not Found)"
        echo "  Secret key: $SECRET_KEY"
        echo "  Please verify the secret key format: account@target@domain"
        exit 1
    else
        print_error "API test failed (HTTP $HTTP_CODE)"
        echo "  Response: $BODY"
        exit 1
    fi
}

# Select deployment type
select_deployment_type() {
    echo ""
    echo -e "${BLUE}Select deployment type:${NC}"
    echo ""
    echo "  1) Init Container (Recommended)"
    echo "     - Fetch secrets at pod startup"
    echo "     - Secrets stored in memory"
    echo "     - Simple and secure"
    echo ""
    echo "  2) CronJob Sync"
    echo "     - Automatic secret synchronization"
    echo "     - Periodic updates (e.g., every 15 min)"
    echo "     - Good for secret rotation"
    echo ""
    echo "  3) Test Connection Only"
    echo "     - Deploy a test pod to verify WALLIX connectivity"
    echo "     - No application deployment"
    echo ""
    
    read -p "Enter choice (1-3): " CHOICE
    
    case $CHOICE in
        1)
            DEPLOYMENT_TYPE="init-container"
            ;;
        2)
            DEPLOYMENT_TYPE="cronjob"
            ;;
        3)
            DEPLOYMENT_TYPE="test"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Select namespace
select_namespace() {
    echo ""
    read -p "Enter namespace (default: wallix-demo): " NAMESPACE
    NAMESPACE=${NAMESPACE:-wallix-demo}
    
    # Check if namespace exists
    if ! $CLI_TOOL get namespace "$NAMESPACE" &> /dev/null; then
        print_warning "Namespace $NAMESPACE does not exist"
        read -p "Create it? (Y/n): " CREATE_NS
        CREATE_NS=${CREATE_NS:-Y}
        
        if [[ "$CREATE_NS" =~ ^[Yy] ]]; then
            $CLI_TOOL create namespace "$NAMESPACE"
            print_success "Namespace $NAMESPACE created"
        else
            print_error "Namespace required for deployment"
            exit 1
        fi
    else
        print_success "Using namespace: $NAMESPACE"
    fi
}

# Deploy init container
deploy_init_container() {
    print_info "Deploying init container pattern..."
    
    # Create API credentials secret
    print_info "Creating WALLIX API credentials secret..."
    $CLI_TOOL create secret generic wallix-api-credentials \
        --from-literal=api-user="$API_USER" \
        --from-literal=api-key="$API_KEY" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | $CLI_TOOL apply -f -
    
    print_success "API credentials secret created"
    
    # Create temporary deployment file with substitutions
    TEMP_FILE=$(mktemp)
    cat "${EXAMPLES_DIR}/init-container-wallix.yaml" | \
        sed "s|namespace: default|namespace: $NAMESPACE|g" | \
        sed "s|YOUR_WALLIX_API_KEY_HERE|$API_KEY|g" | \
        sed "s|https://your-bastion.example.com|$BASTION_URL|g" | \
        sed "s|admin@db-postgres@prod.local|$SECRET_KEY|g" \
        > "$TEMP_FILE"
    
    # Apply the deployment
    print_info "Applying deployment..."
    $CLI_TOOL apply -f "$TEMP_FILE" -n "$NAMESPACE"
    rm "$TEMP_FILE"
    
    print_success "Init container deployment applied"
    
    # Wait for pod to be ready
    print_info "Waiting for pod to be ready..."
    $CLI_TOOL wait --for=condition=ready pod -l app=myapp -n "$NAMESPACE" --timeout=60s || true
    
    echo ""
    print_success "Deployment complete!"
    echo ""
    echo "To check the status:"
    echo "  $CLI_TOOL get pods -n $NAMESPACE"
    echo ""
    echo "To view init container logs:"
    echo "  $CLI_TOOL logs -n $NAMESPACE -l app=myapp -c fetch-wallix-password"
    echo ""
    echo "To view application logs:"
    echo "  $CLI_TOOL logs -n $NAMESPACE -l app=myapp -c app"
}

# Deploy cronjob
deploy_cronjob() {
    print_info "Deploying CronJob pattern..."
    
    # Create API credentials secret
    print_info "Creating WALLIX API credentials secret..."
    $CLI_TOOL create secret generic wallix-api-credentials \
        --from-literal=api-user="$API_USER" \
        --from-literal=api-key="$API_KEY" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | $CLI_TOOL apply -f -
    
    print_success "API credentials secret created"
    
    # Create temporary deployment file with substitutions
    TEMP_FILE=$(mktemp)
    cat "${EXAMPLES_DIR}/cronjob-wallix-sync.yaml" | \
        sed "s|namespace: default|namespace: $NAMESPACE|g" | \
        sed "s|your-bastion.example.com|${BASTION_URL#https://}|g" \
        > "$TEMP_FILE"
    
    # Apply the cronjob
    print_info "Applying CronJob..."
    $CLI_TOOL apply -f "$TEMP_FILE" -n "$NAMESPACE"
    rm "$TEMP_FILE"
    
    print_success "CronJob deployment applied"
    
    echo ""
    print_success "Deployment complete!"
    echo ""
    echo "To trigger the CronJob manually:"
    echo "  $CLI_TOOL create job --from=cronjob/wallix-secrets-sync manual-sync-\$(date +%s) -n $NAMESPACE"
    echo ""
    echo "To check CronJob status:"
    echo "  $CLI_TOOL get cronjob -n $NAMESPACE"
    echo ""
    echo "To view job logs:"
    echo "  $CLI_TOOL logs -n $NAMESPACE -l job-name=<job-name>"
}

# Deploy test pod
deploy_test() {
    print_info "Deploying test pod..."
    
    # Create API credentials secret
    print_info "Creating WALLIX API credentials secret..."
    $CLI_TOOL create secret generic wallix-api-credentials \
        --from-literal=api-user="$API_USER" \
        --from-literal=api-key="$API_KEY" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | $CLI_TOOL apply -f -
    
    print_success "API credentials secret created"
    
    # Create temporary deployment file with substitutions
    TEMP_FILE=$(mktemp)
    cat "${EXAMPLES_DIR}/test-wallix-connection.yaml" | \
        sed "s|namespace: default|namespace: $NAMESPACE|g" | \
        sed "s|https://your-bastion.example.com|$BASTION_URL|g" | \
        sed "s|admin@db-postgres@prod.local|$SECRET_KEY|g" \
        > "$TEMP_FILE"
    
    # Apply the test pod
    print_info "Applying test pod..."
    $CLI_TOOL apply -f "$TEMP_FILE" -n "$NAMESPACE"
    rm "$TEMP_FILE"
    
    # Wait for pod to complete
    print_info "Waiting for test to complete..."
    sleep 5
    
    print_success "Test pod deployed"
    
    echo ""
    echo "To view test results:"
    echo "  $CLI_TOOL logs -n $NAMESPACE wallix-connection-test"
}

# Main deployment flow
main() {
    check_cluster_access
    echo ""
    load_config
    echo ""
    test_wallix_api
    echo ""
    select_deployment_type
    select_namespace
    echo ""
    
    case $DEPLOYMENT_TYPE in
        "init-container")
            deploy_init_container
            ;;
        "cronjob")
            deploy_cronjob
            ;;
        "test")
            deploy_test
            ;;
    esac
    
    echo ""
    print_success "All done! 🎉"
}

# Run main function
main
