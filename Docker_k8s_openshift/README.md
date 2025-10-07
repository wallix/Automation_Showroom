# Docker, Kubernetes & OpenShift Integration

This directory contains comprehensive integration examples and tools for deploying WALLIX Bastion with containerized environments.

## Overview

WALLIX Bastion provides privileged access management (PAM) capabilities for securing access to critical resources. This collection demonstrates various integration patterns for containerized platforms.

## Available Integrations

### OpenShift

Complete integration examples for Red Hat OpenShift and Kubernetes platforms.

**Key Features:**

- Secret management and synchronization
- Multiple integration approaches (simple and advanced)
- Production-ready examples
- Security best practices

See [Openshift/](./Openshift/) for detailed documentation.

## Quick Navigation

| Integration | Complexity | Use Case | Documentation |
|------------|-----------|----------|---------------|
| **Simple Integration** | Low | Direct API integration, Init containers | [WALLIX_Simple_Integration](./Openshift/WALLIX_Simple_Integration/) |
| **External Secrets Operator** | Medium | Advanced secret synchronization | [External_Secrets_Operator](./Openshift/External_Secrets_Operator/) |
| **Basics** | Low | Secret transfer scripts | [Basics](./Openshift/Basics/) |

## Getting Started

1. **Choose Your Approach:**
   - For most use cases: Start with [Simple Integration](./Openshift/WALLIX_Simple_Integration/)
   - For advanced automation: Explore [External Secrets Operator](./Openshift/External_Secrets_Operator/)
   - For one-time transfers: Use [Basic Scripts](./Openshift/Basics/)

2. **Prerequisites:**
   - WALLIX Bastion 12.0+ with API access
   - OpenShift/Kubernetes cluster
   - Network connectivity between cluster and WALLIX
   - Valid API credentials

3. **Follow Documentation:**
   Each integration folder contains detailed README files with setup instructions and examples.

## Integration Patterns

### 1. Init Container Pattern

Pull secrets at pod startup using init containers. Best for:

- One-time secret retrieval
- Simple deployments
- No external dependencies

### 2. CronJob Synchronization

Periodic secret updates using scheduled jobs. Best for:

- Regular password rotation
- Multiple applications
- Centralized secret management

### 3. External Secrets Operator

Automated secret synchronization with ESO. Best for:

- GitOps workflows
- Enterprise environments
- Multi-provider secret management

## Security Considerations

- All examples use HTTPS for API communication
- Self-signed certificates supported (with `-k` flag)
- Secrets stored in Kubernetes/OpenShift native secret objects
- No persistent storage of credentials in containers
- API authentication using session tokens

## Support

For issues, questions, or contributions:

- Check individual integration documentation
- Review troubleshooting guides in each folder
- Consult WALLIX Bastion API documentation

## Related Resources

- [WALLIX Bastion Documentation](https://doc.wallix.com/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [External Secrets Operator](https://external-secrets.io/)
