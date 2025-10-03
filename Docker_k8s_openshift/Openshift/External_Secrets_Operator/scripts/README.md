# 🛠️ External Secrets Operator - Scripts Documentation

Automation and management scripts for WALLIX Bastion integration with External Secrets Operator.

## 📋 Table of Contents

- [Overview](#overview)
- [Scripts](#scripts)
  - [test-connection.sh](#test-connectionsh)
  - [validate-secrets.sh](#validate-secretssh)
  - [monitor.sh](#monitorsh)
  - [cleanup.sh](#cleanupsh)
  - [generate-readme.sh](#generate-readmesh)
- [Configuration](#configuration)
- [Examples](#examples)

---

## Overview

These scripts help you:

- ✅ Test WALLIX Bastion API connectivity
- ✅ Validate ExternalSecret synchronization
- ✅ Monitor ESO resources in real-time
- ✅ Clean up resources safely
- ✅ Generate documentation from deployed resources

## Scripts

### test-connection.sh

**Purpose:** Test connectivity to WALLIX Bastion API and validate credentials.

**Usage:**

```bash
# Interactive mode
./test-connection.sh

# Environment variables mode
export WALLIX_URL="https://bastion.example.com"
export WALLIX_USER="admin"
export WALLIX_KEY="your-api-key"
export WALLIX_TARGET="admin@database@prod.local"
./test-connection.sh

# Config file mode
cat > wallix-config.env <<EOF
WALLIX_URL="https://bastion.example.com"
WALLIX_USER="admin"
WALLIX_KEY="your-api-key"
WALLIX_TARGET="admin@database@prod.local"
EOF
./test-connection.sh -c wallix-config.env
```

**Options:**

- `-c, --config FILE` - Load configuration from file
- `-h, --help` - Show help message
- `-v, --verbose` - Enable verbose output

**Features:**

- ✅ Tests basic connectivity (HTTP 200/302)
- ✅ Validates authentication (X-Auth-User + X-Auth-Key)
- ✅ Tests specific target password checkout
- ✅ Handles self-signed certificates
- ✅ Provides detailed error messages
- ✅ Exports results for automation

**Exit Codes:**

- `0` - Success
- `1` - Connection failed
- `2` - Authentication failed
- `3` - Target not found
- `4` - Invalid configuration

**Example Output:**

```
🔍 Testing WALLIX Bastion Connection
=====================================

📡 Testing connectivity...
✅ WALLIX Bastion is reachable (HTTP 302)

🔐 Testing authentication...
✅ Authentication successful

🎯 Testing target password checkout...
Target: admin@database@prod.local
✅ Password retrieved successfully
Password: **************** (14 characters)

🎉 All tests passed!
```

---

### validate-secrets.sh

**Purpose:** Validate all ExternalSecrets and their synchronized Kubernetes secrets.

**Usage:**

```bash
# Validate all ExternalSecrets in all namespaces
./validate-secrets.sh

# Validate specific namespace
./validate-secrets.sh -n default

# Validate specific ExternalSecret
./validate-secrets.sh -n default -e my-secret

# Watch mode (continuous validation)
./validate-secrets.sh --watch

# JSON output for automation
./validate-secrets.sh --json
```

**Options:**

- `-n, --namespace NAMESPACE` - Target namespace (default: all)
- `-e, --external-secret NAME` - Specific ExternalSecret name
- `-w, --watch` - Continuous validation mode (refresh every 30s)
- `-j, --json` - Output in JSON format
- `-q, --quiet` - Minimal output
- `-h, --help` - Show help message

**Features:**

- ✅ Checks ExternalSecret sync status
- ✅ Validates target Secret exists
- ✅ Verifies Secret data integrity
- ✅ Shows password character count (not actual password)
- ✅ Reports sync errors with details
- ✅ Color-coded output
- ✅ JSON output for CI/CD integration

**Example Output:**

```
📊 Validating ExternalSecrets
==============================

Namespace: default
------------------

ExternalSecret: database-credentials
  Status: ✅ SecretSynced
  Secret: db-password-secret
  Keys: password (14 chars)
  Last Sync: 2m ago

ExternalSecret: api-credentials
  Status: ⚠️  SecretSyncErr
  Error: invalid key format
  
Summary:
--------
Total: 2
✅ Synced: 1
❌ Failed: 1
```

---

### monitor.sh

**Purpose:** Real-time monitoring of ESO resources with automatic refresh.

**Usage:**

```bash
# Start monitoring (default: 10s refresh)
./monitor.sh

# Custom refresh interval
./monitor.sh -i 5

# Monitor specific namespace
./monitor.sh -n default

# Compact view
./monitor.sh --compact

# Export metrics
./monitor.sh --metrics > metrics.json
```

**Options:**

- `-i, --interval SECONDS` - Refresh interval (default: 10)
- `-n, --namespace NAMESPACE` - Target namespace (default: all)
- `-c, --compact` - Compact view (less details)
- `-m, --metrics` - Export Prometheus-style metrics
- `-l, --log FILE` - Log output to file
- `-h, --help` - Show help message

**Features:**

- ✅ Live view of ESO pods, SecretStores, ExternalSecrets
- ✅ Resource status and health checks
- ✅ Recent events display
- ✅ Color-coded status indicators
- ✅ Metrics export for monitoring systems
- ✅ Log to file option
- ✅ Keyboard controls (q=quit, r=refresh)

**Dashboard View:**

```
🔄 ESO Monitoring Dashboard (refresh: 10s) | Press 'q' to quit, 'r' to refresh
================================================================================

⚙️  ESO Pods (external-secrets-system)
   external-secrets-768b5d8d5f-xxxxx        ✅ Running (1/1)
   external-secrets-webhook-xxxxx-xxxxx     ✅ Running (1/1)

🏪 SecretStores
   Namespace    Name              Status    Ready   Age
   default      wallix-bastion    Valid     True    2h
   prod         wallix-bastion    Valid     True    1h

🔐 ExternalSecrets
   Namespace    Name                Status         Secret                Age
   default      db-creds            SecretSynced   db-password           2h
   prod         api-creds           SecretSynced   api-credentials       1h

📊 Summary
   SecretStores: 2 (2 ready)
   ExternalSecrets: 2 (2 synced, 0 failed)
   Secrets: 2 (2 valid)

📝 Recent Events (last 5)
   10s   ExternalSecret/db-creds       SecretSynced
   2m    SecretStore/wallix-bastion    Valid
```

---

### cleanup.sh

**Purpose:** Safely remove ESO resources with confirmation prompts.

**Usage:**

```bash
# Interactive cleanup (prompts for confirmation)
./cleanup.sh

# Cleanup specific namespace
./cleanup.sh -n default

# Cleanup specific resource type
./cleanup.sh --only-externalsecrets

# Force cleanup (no prompts)
./cleanup.sh --force

# Dry run (show what would be deleted)
./cleanup.sh --dry-run

# Complete uninstall (ESO + CRDs)
./cleanup.sh --uninstall
```

**Options:**

- `-n, --namespace NAMESPACE` - Target namespace (default: all)
- `-f, --force` - Skip confirmation prompts
- `-d, --dry-run` - Show what would be deleted
- `--only-externalsecrets` - Only delete ExternalSecrets
- `--only-secretstores` - Only delete SecretStores
- `--keep-secrets` - Keep generated Kubernetes secrets
- `--uninstall` - Complete ESO uninstall (Helm + CRDs)
- `-h, --help` - Show help message

**Features:**

- ✅ Safe deletion with confirmations
- ✅ Dry-run mode
- ✅ Selective cleanup options
- ✅ Backup resources before deletion
- ✅ Complete uninstall support
- ✅ Detailed deletion report

**Cleanup Sequence:**

1. **Backup** resources to `./backups/TIMESTAMP/`
2. **Delete ExternalSecrets** (oldest to newest)
3. **Delete SecretStores** and ClusterSecretStores
4. **Optionally delete** generated Kubernetes secrets
5. **Optionally uninstall** ESO Helm chart
6. **Optionally delete** CRDs

**Example Output:**

```
🧹 ESO Cleanup Utility
======================

🔍 Scanning resources...

Found:
  - 3 ExternalSecrets
  - 2 SecretStores
  - 1 ClusterSecretStore
  - 3 Generated Secrets

📦 Backing up resources to: ./backups/2024-01-15_10-30-45/

⚠️  This will delete:
  - ExternalSecrets: db-creds, api-creds, ssh-keys
  - SecretStores: wallix-bastion (default), wallix-bastion (prod)
  - ClusterSecretStore: wallix-bastion-global

Continue? (y/N): y

🗑️  Deleting ExternalSecrets...
  ✅ Deleted externalsecret/db-creds (default)
  ✅ Deleted externalsecret/api-creds (prod)
  ✅ Deleted externalsecret/ssh-keys (prod)

🗑️  Deleting SecretStores...
  ✅ Deleted secretstore/wallix-bastion (default)
  ✅ Deleted secretstore/wallix-bastion (prod)
  ✅ Deleted clustersecretstore/wallix-bastion-global

Keep generated secrets? (Y/n): n

🗑️  Deleting generated secrets...
  ✅ Deleted secret/db-password (default)
  ✅ Deleted secret/api-credentials (prod)
  ✅ Deleted secret/ssh-key (prod)

✅ Cleanup complete!

📁 Backup saved to: ./backups/2024-01-15_10-30-45/
```

---

### generate-readme.sh

**Purpose:** Auto-generate documentation from deployed ESO resources.

**Usage:**

```bash
# Generate README from current resources
./generate-readme.sh

# Specify output file
./generate-readme.sh -o DEPLOYMENT.md

# Include examples in output
./generate-readme.sh --include-examples

# Generate for specific namespace
./generate-readme.sh -n production

# Output format
./generate-readme.sh --format markdown  # or json, yaml
```

**Options:**

- `-o, --output FILE` - Output file (default: GENERATED_README.md)
- `-n, --namespace NAMESPACE` - Target namespace (default: all)
- `-f, --format FORMAT` - Output format: markdown, json, yaml (default: markdown)
- `-e, --include-examples` - Include resource examples
- `-s, --include-secrets` - Include secret references (no values)
- `-t, --template FILE` - Use custom template
- `-h, --help` - Show help message

**Features:**

- ✅ Scans all ESO resources
- ✅ Generates structured documentation
- ✅ Includes configuration examples
- ✅ Creates deployment guide
- ✅ Lists all ExternalSecrets and their targets
- ✅ Multiple output formats
- ✅ Template support for customization

**Generated Documentation Includes:**

1. **Overview** - Deployment summary
2. **SecretStores** - List and configuration
3. **ExternalSecrets** - Inventory with targets
4. **Secrets** - Generated Kubernetes secrets (no values)
5. **Quick Start** - Deployment commands
6. **Troubleshooting** - Common issues
7. **Examples** - YAML configurations

**Example Output:**

```
# ESO Deployment Documentation
Generated: 2024-01-15 10:30:45

## Overview
This deployment uses External Secrets Operator to sync secrets from WALLIX Bastion.

Total Resources:
- SecretStores: 2
- ExternalSecrets: 5
- Synced Secrets: 5

## SecretStores

### wallix-bastion (default)
- Provider: Webhook (WALLIX)
- URL: https://bastion.example.com/api/targetpasswords/checkout/*
- Status: Valid ✅

### wallix-bastion (production)
- Provider: Webhook (WALLIX)
- URL: https://bastion-prod.example.com/api/targetpasswords/checkout/*
- Status: Valid ✅

## ExternalSecrets

### database-credentials (default)
- SecretStore: wallix-bastion
- Target Secret: db-password
- WALLIX Key: admin@postgres@prod.local
- Status: SecretSynced ✅

[... continues with all resources ...]
```

---

## Configuration

### Environment Variables

All scripts support these environment variables:

```bash
# WALLIX Configuration
export WALLIX_URL="https://bastion.example.com"
export WALLIX_USER="admin"
export WALLIX_KEY="your-api-key"
export WALLIX_TARGET="admin@target@domain"

# Script Behavior
export ESO_NAMESPACE="default"              # Target namespace
export ESO_DEBUG="true"                     # Enable debug mode
export ESO_COLOR="true"                     # Enable color output
export ESO_TIMEOUT="30"                     # API timeout (seconds)
```

### Configuration File

Create `wallix-config.env`:

```bash
# WALLIX Bastion Configuration
WALLIX_URL="https://bastion.example.com"
WALLIX_USER="admin"
WALLIX_KEY="BZFeA8mwcAjnvTuNVkJ4PwZZMyM5tnKEpcBoaopO64I"
WALLIX_TARGET="admin@database@prod.local"

# Optional Settings
WALLIX_SKIP_TLS_VERIFY="true"
WALLIX_TIMEOUT="30"
```

Load configuration:

```bash
source wallix-config.env
./test-connection.sh
```

---

## Examples

### Automated Testing in CI/CD

```bash
#!/bin/bash
# ci-test.sh

set -e

# Test connection
./scripts/test-connection.sh -c config/wallix-prod.env || exit 1

# Validate all secrets
./scripts/validate-secrets.sh --json > validation-results.json

# Check for failures
FAILED=$(jq '.failed' validation-results.json)
if [ "$FAILED" -gt 0 ]; then
  echo "❌ $FAILED secrets failed validation"
  exit 1
fi

echo "✅ All secrets validated successfully"
```

### Monitoring with Prometheus

```bash
#!/bin/bash
# Export metrics every 60s

while true; do
  ./scripts/monitor.sh --metrics > /var/lib/prometheus/eso-metrics.prom
  sleep 60
done
```

### Scheduled Secret Validation

```bash
# Crontab entry: validate every hour
0 * * * * /path/to/scripts/validate-secrets.sh --quiet >> /var/log/eso-validation.log 2>&1
```

### Safe Cleanup with Backup

```bash
#!/bin/bash
# cleanup-with-backup.sh

BACKUP_DIR="./backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup all ESO resources
kubectl get externalsecret -A -o yaml > "$BACKUP_DIR/externalsecrets.yaml"
kubectl get secretstore -A -o yaml > "$BACKUP_DIR/secretstores.yaml"
kubectl get clustersecretstore -o yaml > "$BACKUP_DIR/clustersecretstores.yaml"

echo "✅ Backup saved to: $BACKUP_DIR"

# Now run cleanup
./scripts/cleanup.sh --force
```

### Watch Mode for Development

```bash
# Terminal 1: Monitor ESO resources
./scripts/monitor.sh -i 5

# Terminal 2: Watch logs
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets -f

# Terminal 3: Validate secrets in real-time
watch -n 10 './scripts/validate-secrets.sh --quiet'
```

---

## Troubleshooting Scripts

### Script Not Executable

```bash
# Make all scripts executable
chmod +x scripts/*.sh
```

### Missing Dependencies

```bash
# Install required tools
# Ubuntu/Debian
sudo apt-get install jq curl

# macOS
brew install jq curl

# RHEL/CentOS
sudo yum install jq curl
```

### Permission Denied

```bash
# Check kubectl access
kubectl auth can-i get externalsecrets
kubectl auth can-i get secretstores

# Use service account if needed
export KUBECONFIG=/path/to/service-account-kubeconfig
```

---

## Best Practices

1. **Always use dry-run first**

   ```bash
   ./cleanup.sh --dry-run
   ```

2. **Backup before cleanup**

   ```bash
   kubectl get externalsecret -A -o yaml > backup.yaml
   ./cleanup.sh
   ```

3. **Monitor in production**

   ```bash
   ./monitor.sh -i 30 --log /var/log/eso-monitor.log
   ```

4. **Validate regularly**

   ```bash
   # Add to cron
   0 */6 * * * /path/to/validate-secrets.sh --quiet
   ```

5. **Use config files for automation**

   ```bash
   # Don't hardcode credentials
   ./test-connection.sh -c /etc/wallix/config.env
   ```

---

## Script Dependencies

| Script                | Dependencies                          |
| --------------------- | ------------------------------------- |
| test-connection.sh    | `curl`, `jq`, `bash 4+`               |
| validate-secrets.sh   | `kubectl`, `jq`, `bash 4+`            |
| monitor.sh            | `kubectl`, `watch`, `bash 4+`         |
| cleanup.sh            | `kubectl`, `helm` (for uninstall)     |
| generate-readme.sh    | `kubectl`, `jq`, `bash 4+`            |

---

## Support

For issues with scripts:

1. Enable debug mode: `export ESO_DEBUG=true`
2. Check script permissions: `ls -la scripts/`
3. Verify dependencies: `which kubectl jq curl`
4. Review logs: `./scripts/monitor.sh --log debug.log`

See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for more help.
