# External Secrets Operator with WALLIX Bastion

> **⚠️ Advanced Solution** - For most use cases, see **[WALLIX_Simple_Integration](../WALLIX_Simple_Integration/)** (recommended)

Complete production-ready solution for integrating External Secrets Operator (ESO) with WALLIX Bastion privileged access management.

## 🎯 Overview

External Secrets Operator synchronizes secrets from WALLIX Bastion into Kubernetes/OpenShift, enabling:

- ✅ **Centralized Secret Management** - Store all privileged passwords in WALLIX
- ✅ **Automatic Synchronization** - Secrets auto-sync to Kubernetes/OpenShift
- ✅ **Password Rotation** - Automatic updates when passwords change in WALLIX
- ✅ **Security Compliance** - Maintain audit trails and access controls
- ✅ **GitOps Compatible** - Declare secrets in git without exposing values
- ✅ **Multi-Provider Support** - Integrate with Vault, AWS, Azure, and more

### 🔐 Enhanced Security with WALLIX AAPM

For maximum security hardening, consider combining this solution with **WALLIX AAPM**:

- **🛡️ Container-Level Security** - Secure applications directly at runtime
- **🔑 Secret Zero Protection** - Eliminate initial bootstrap credentials exposure
- **📊 Application Monitoring** - Real-time visibility into application access patterns
- **🚫 Zero-Trust Architecture** - Remove hard-coded secrets from containers entirely
- **🔄 Dynamic Credential Injection** - Just-in-time credential provisioning

This approach provides defense-in-depth security for your containerized applications while maintaining the flexibility of external secret management.

## 📚 Documentation

| Document | Description | Time Required |
|----------|-------------|---------------|
| **[INSTALLATION.md](./INSTALLATION.md)** | Complete installation & quick start guide | 30-60 min |
| **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** | Common issues and solutions | As needed |
| **[scripts/README.md](./scripts/README.md)** | Automation scripts documentation | Reference |

## ❓ When to Use This Solution

**Use External Secrets Operator if:**

- ✅ You already have ESO installed in your cluster
- ✅ You manage multiple secret providers (Vault, AWS Secrets Manager, Azure Key Vault, etc.)
- ✅ You have an experienced Kubernetes team
- ✅ You need advanced features (ClusterSecretStore, PushSecret, multi-tenancy)
- ✅ You want automatic secret rotation with external systems

**Use Simple Integration if:**

- ❌ You only need WALLIX Bastion integration
- ❌ You want a 5-minute setup with no dependencies
- ❌ You prefer simple init containers or CronJobs
- ❌ You're new to Kubernetes/OpenShift

## 🚀 Quick Start (30 Minutes)

See **[INSTALLATION.md](./INSTALLATION.md)** for the complete step-by-step installation guide.

### Key Steps

1. **Install ESO** - Deploy External Secrets Operator via Helm
2. **Configure WALLIX** - Create API credentials and SecretStore
3. **Create ExternalSecret** - Sync passwords from WALLIX to Kubernetes
4. **Verify** - Test the integration

**⚠️ Important Notes:**

- ESO v0.20+ uses API version `v1` (not `v1beta1`)
- Certificate validation required (no `insecureSkipVerify` in v0.20+)
- Use DNS hostname instead of IP address for WALLIX URL

## 📁 Directory Structure

```ini
External_Secrets_Operator/
├── README.md                       # This file
├── QUICKSTART.md                   # 15-minute quick start
├── INSTALLATION.md                 # Complete installation guide
├── TROUBLESHOOTING.md              # Troubleshooting guide
├── examples/                       # YAML configurations
│   ├── wallix-secretstore-official.yaml
│   ├── deployment-example.yaml
│   ├── configmap-example.yaml
│   ├── init-container-wallix.yaml
│   └── cronjob-wallix-sync.yaml
├── scripts/                        # Automation scripts
│   ├── README.md                   # Scripts documentation
│   ├── test-connection.sh          # Test WALLIX API
│   ├── validate-secrets.sh         # Validate ExternalSecrets
│   ├── monitor.sh                  # Real-time monitoring
│   ├── cleanup.sh                  # Safe cleanup
│   └── generate-readme.sh          # Generate docs
└── OLD/                           # Archived installation attempts
```

## 🔧 Key Features

### SecretStore Configuration

Connects ESO to WALLIX Bastion using webhook provider:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: wallix-bastion
spec:
  provider:
    webhook:
      url: "https://WALLIX-URL/api/targetpasswords/checkout/{{ .remoteRef.key }}"
      method: GET
      headers:
        X-Auth-User: "{{ .authUser }}"
        X-Auth-Key: "{{ .authKey }}"
      secrets:
      - name: authUser
        secretRef:
          name: wallix-api-credentials
          key: api-user
      - name: authKey
        secretRef:
          name: wallix-api-credentials
          key: api-key
      result:
        jsonPath: "$.password"
```

**Key Points:**

- Both `X-Auth-User` and `X-Auth-Key` headers **required**
- URL template uses `{{ .remoteRef.key }}` placeholder
- JSONPath extracts password from API response
- Supports self-signed certificates via `caBundle`

### ExternalSecret Configuration

Define which WALLIX passwords to sync:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h              # Sync frequency
  secretStoreRef:
    name: wallix-bastion
  target:
    name: db-password-secret       # Kubernetes secret name
    creationPolicy: Owner
  data:
  - secretKey: password            # Key in secret
    remoteRef:
      key: admin@postgres@prod     # WALLIX target
```

**WALLIX Target Format:** `account@target@domain`

## 🛠️ Automation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| **[test-connection.sh](./scripts/README.md#test-connectionsh)** | Test WALLIX API | `./scripts/test-connection.sh` |
| **[validate-secrets.sh](./scripts/README.md#validate-secretssh)** | Validate sync status | `./scripts/validate-secrets.sh` |
| **[monitor.sh](./scripts/README.md#monitorsh)** | Real-time monitoring | `./scripts/monitor.sh` |
| **[cleanup.sh](./scripts/README.md#cleanupsh)** | Safe cleanup | `./scripts/cleanup.sh --dry-run` |
| **[generate-readme.sh](./scripts/README.md#generate-readmesh)** | Generate docs | `./scripts/generate-readme.sh` |

**See [scripts/README.md](./scripts/README.md) for complete documentation.**

## 📊 Examples

### Multiple Passwords

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: multi-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: wallix-bastion
  target:
    name: application-secrets
    creationPolicy: Owner
  data:
  - secretKey: db-password
    remoteRef:
      key: admin@postgres@prod.local
  - secretKey: api-key
    remoteRef:
      key: apiuser@external-api@prod.local
  - secretKey: ssh-key
    remoteRef:
      key: deploy@gitserver@prod.local
```

### Using in Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-password-secret  # From ExternalSecret
              key: password
```

**More examples:** [examples/](./examples/)

## 🔍 Testing & Validation

```bash
# Test WALLIX connection
./scripts/test-connection.sh

# Validate all ExternalSecrets
./scripts/validate-secrets.sh

# Monitor in real-time
./scripts/monitor.sh

# Check specific secret
kubectl get externalsecret my-secret
kubectl get secret app-credentials -o yaml
```

## 🚨 Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| **SecretStore not ready** | `./scripts/test-connection.sh` |
| **ExternalSecret not syncing** | Check format: `account@target@domain` |
| **Certificate errors** | Add `caProvider` with CA certificate |
| **401/403 errors** | Verify both auth headers present |

**Complete guide:** [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

## 📊 Comparison: ESO vs Simple Integration

| Feature | ESO (Advanced) | [Simple Integration](../WALLIX_Simple_Integration/) |
|---------|---------------|---------------------|
| **Setup Time** | 30-60 min | 5 min ⚡ |
| **Dependencies** | Helm, ESO | None (curl, jq) |
| **Complexity** | High | Low |
| **Multi-Provider** | ✅ Yes | ❌ WALLIX only |
| **Auto-Refresh** | ✅ Built-in | Manual/CronJob |
| **Best For** | Existing ESO users | Quick WALLIX integration |

## 🧹 Cleanup

```bash
# Safe cleanup with prompts
./scripts/cleanup.sh

# Dry run
./scripts/cleanup.sh --dry-run

# Complete uninstall
./scripts/cleanup.sh --uninstall
```

## 📚 Resources

- **[External Secrets Operator Docs](https://external-secrets.io/)** - Official documentation
- **[Webhook Provider Guide](https://external-secrets.io/latest/provider/webhook/)** - Webhook details
- **[WALLIX API Docs](https://documentation.wallix.com)** - WALLIX API reference
- **[Simple Integration](../WALLIX_Simple_Integration/)** - Recommended for most cases

## 📝 Best Practices

1. ✅ Use **ClusterSecretStore** for shared credentials across namespaces
2. ✅ Set `refreshInterval: 1h` (balance freshness vs API load)
3. ✅ Use **caBundle** for production (not `insecureSkipVerify`)
4. ✅ **Monitor sync status** with `./scripts/monitor.sh`
5. ✅ **Backup before cleanup** - `kubectl get ... -o yaml`
6. ✅ **Test changes** with `--dry-run` first
7. ✅ **Document WALLIX targets** - Maintain inventory

## 🆘 Getting Help

1. **Documentation**
   - [INSTALLATION.md](./INSTALLATION.md) - Complete setup guide
   - [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues
   - [scripts/README.md](./scripts/README.md) - Scripts guide

2. **Diagnostics**

   ```bash
   ./scripts/test-connection.sh    # Test WALLIX
   ./scripts/validate-secrets.sh   # Validate setup
   ./scripts/monitor.sh            # Check status
   ```

3. **Community**
   - [ESO GitHub](https://github.com/external-secrets/external-secrets/issues)
   - [ESO Slack](https://kubernetes.slack.com/archives/external-secrets)
   - [WALLIX Support](https://www.wallix.com/support/)

## 🎯 Next Steps

- ✅ Complete [INSTALLATION.md](./INSTALLATION.md) (30-60 min)
- ✅ Review [examples/](./examples/) for your use case
- ✅ Set up monitoring: `./scripts/monitor.sh`
- ✅ Configure alerts for sync failures
- ✅ Plan backup and DR strategy
- ✅ Document your WALLIX target inventory

---

**💡 Reminder:** For simpler WALLIX-only integration, see **[WALLIX_Simple_Integration](../WALLIX_Simple_Integration/)** - 5-minute setup, no dependencies!
