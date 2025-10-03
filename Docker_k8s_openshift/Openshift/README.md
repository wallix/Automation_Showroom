# WALLIX Bastion - OpenShift Integration

This directory contains integration examples and tools for using WALLIX Bastion with Red Hat OpenShift and Kubernetes platforms.

## Available Solutions

### 1. Basics

**Difficulty:** Beginner  
**Use Case:** One-time secret transfers from WALLIX to OpenShift

Simple bash scripts to pull secrets from WALLIX Bastion API and create them as OpenShift secrets.

**Key Features:**

- Command-line secret retrieval
- Direct API integration
- Secure password prompting
- Namespace support
- Dry-run mode

[View Documentation →](./Basics/)

---

### 2. WALLIX Simple Integration

**Difficulty:** Beginner to Intermediate  
**Use Case:** Production deployments without external dependencies

Recommended approach for most use cases. Provides reliable methods to retrieve secrets at runtime.

**Key Features:**

- Init container pattern for startup secrets
- CronJob synchronization for periodic updates
- No external operator required
- Memory-only secret storage
- Production-ready examples

[View Documentation →](./WALLIX_Simple_Integration/)

---

### 3. External Secrets Operator

**Difficulty:** Advanced  
**Use Case:** Enterprise environments with complex secret management needs

Integration with External Secrets Operator for automated secret synchronization.

**Key Features:**

- Automated secret synchronization
- GitOps-friendly declarative configuration
- Password rotation support
- Multi-provider secret management
- Audit trail integration

[View Documentation →](./External_Secrets_Operator/)

## Choosing the Right Solution

| Requirement | Recommended Solution |
|------------|---------------------|
| Simple secret retrieval | Basics |
| Production applications | WALLIX Simple Integration |
| One-time pod secrets | Init Container (Simple Integration) |
| Periodic secret updates | CronJob (Simple Integration) |
| GitOps workflows | External Secrets Operator |
| Enterprise environments | External Secrets Operator |
| No external dependencies | WALLIX Simple Integration |

## Prerequisites

- WALLIX Bastion 12.0 or later
- OpenShift 4.x or Kubernetes 1.19+
- Network access from cluster to WALLIX Bastion
- WALLIX API credentials (username/password)
- `oc` or `kubectl` CLI tool

## Quick Start

### Option 1: Basic Secret Transfer (Fastest)

```bash
cd Basics
WALLIX_PASSWORD=your_password ./pull_secret_to_vault.sh admin@server@domain
```

### Option 2: Init Container (Recommended)

```bash
cd WALLIX_Simple_Integration/examples
oc apply -f init-container-wallix.yaml
```

### Option 3: External Secrets Operator (Advanced)

```bash
cd External_Secrets_Operator
# Follow INSTALLATION.md for complete setup
```

## Common Use Cases

### Retrieve Database Password

```bash
# Using basic script
WALLIX_PASSWORD=mypass ./Basics/pull_secret_to_vault.sh postgres@dbserver@local

# Creates OpenShift secret: postgres-dbserver-local
```

### Application Deployment with Secrets

```yaml
# Using init container
apiVersion: v1
kind: Pod
spec:
  initContainers:
  - name: wallix-secret-fetcher
    # See WALLIX_Simple_Integration/examples/
```

### Automated Secret Sync

```yaml
# Using External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
# See External_Secrets_Operator/examples/
```

## Security Best Practices

- Use service accounts with minimal required permissions
- Store WALLIX credentials in OpenShift secrets
- Enable TLS verification in production (configure CA certificates)
- Use namespace isolation for sensitive secrets
- Implement RBAC policies for secret access
- Rotate WALLIX API credentials regularly
- Monitor secret access through WALLIX audit logs

## Architecture Overview

### Simple Integration Flow

```
WALLIX Bastion API → Init Container → Shared Volume → Application Container
```

### External Secrets Operator Flow

```
WALLIX Bastion API → ESO Controller → Kubernetes Secret → Application Pod
```

## Troubleshooting

### Connection Issues

- Verify network connectivity: `curl -k https://wallix-host/api/version`
- Check firewall rules between cluster and WALLIX
- Validate API credentials

### Secret Not Found

- Verify target name format: `account@device@domain`
- Check WALLIX authorization configuration
- Review user permissions in WALLIX

### Certificate Errors

- For testing: Use `-k` flag (insecure)
- For production: Add WALLIX CA to trusted certificates

For detailed troubleshooting, see:

- [WALLIX_Simple_Integration/README.md](./WALLIX_Simple_Integration/README.md)
- [External_Secrets_Operator/TROUBLESHOOTING.md](./External_Secrets_Operator/TROUBLESHOOTING.md)

## Resources

- WALLIX Bastion API v3.12 documentation
- OpenShift secret management guide
- External Secrets Operator documentation
- Kubernetes security best practices

## Support

Each integration folder contains:

- Detailed README with setup instructions
- Working examples and templates
- Configuration references
- Troubleshooting guides
