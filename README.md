# WALLIX Automation Showroom

[![All Contributors](https://img.shields.io/badge/all_contributors-3-green.svg?style=flat-square)](#contributors-)
[![Production Ready](https://img.shields.io/badge/status-production--ready-green)](Ansible/Provisioning/Advanced/)
[![WALLIX API](https://img.shields.io/badge/WALLIX%20API-v3.12-blue)](https://www.wallix.com/)

Comprehensive automation examples and production-ready tools for WALLIX Bastion Host management across multiple cloud providers and deployment scenarios.

> **Note**: This framework is actively developed with regular improvements and new features.

## Overview

Enterprise-grade automation patterns for:

- **Infrastructure as Code**: Deploy WALLIX Bastion across AWS, Azure, GCP
- **Configuration Management**: Complete WALLIX Bastion automation with Ansible
- **Cloud Integration**: Ready-to-use cloud-init templates and deployment scripts
- **API Automation**: Full WALLIX API v3.12 integration

## Repository Structure

```text
Automation_Showroom/
├── Ansible/Provisioning/Advanced/    # Production-ready Ansible automation
├── Terraform/                        # Infrastructure as Code templates
├── cloud-init/                       # Cloud deployment automation
├── pulumi/                           # Modern IaC examples
└── Docker_k8s_openshift/            # Container and orchestration
```

## Quick Start

### 1. Ansible Automation (Recommended)

```bash
cd Ansible/Provisioning/Advanced
./scripts/setup-vault.sh
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass
```

See [Ansible Advanced README](Ansible/Provisioning/Advanced/README.md) for complete guide.

### 2. Infrastructure Deployment

```bash
# Terraform
cd Terraform/Deploying/aws && terraform init && terraform apply

# Pulumi  
cd pulumi/bastion4gcp && pulumi up
```

### 3. Cloud Deployment

```bash
cd cloud-init
python3 wallix_cloud_init_generator.py
```

## Components

### Ansible Advanced Automation

**Status**: Production Ready | **Last Tested**: October 3, 2025 | **WALLIX Version**: v12.0.15

Complete WALLIX Bastion management with:

- Automated setup and configuration
- User, device, and authorization management
- Multi-environment support (dev/staging/prod)
- Advanced cleanup with safety mechanisms

→ [Full Documentation](Ansible/Provisioning/Advanced/README.md)

### Infrastructure as Code

- **Terraform**: Multi-cloud deployment templates (AWS, Azure, GCP)
- **Pulumi**: Modern infrastructure automation
- **Cloud-Init**: Automated WALLIX installation

→ [Terraform Guide](Terraform/README.md) | [Cloud-Init Guide](cloud-init/README.md)

### Container & Orchestration

- **Docker**: Container deployment examples
- **Kubernetes/OpenShift**: Orchestration manifests

→ [Container Documentation](Docker_k8s_openshift/README.md)

## Documentation

- [CHANGELOG](CHANGELOG.md) - Release history and updates
- [Advanced Ansible](Ansible/Provisioning/Advanced/README.md) - Complete automation guide
- [Terraform](Terraform/README.md) - Infrastructure deployment
- [Cloud-Init](cloud-init/README.md) - Cloud automation

## Requirements

- **Ansible**: 2.9+ for configuration management
- **Terraform**: 0.14+ for infrastructure
- **Python**: 3.6+ for scripts and tools
- **WALLIX Bastion**: API access for testing

## Getting Started

1. **Clone the repository**

   ```bash
   git clone https://github.com/wallix/Automation_Showroom.git
   cd Automation_Showroom
   ```

2. **Choose your path**
   - **Ansible**: `cd Ansible/Provisioning/Advanced && ./scripts/setup-vault.sh`
   - **Terraform**: `cd Terraform/Deploying/aws`
   - **Cloud-Init**: `cd cloud-init`

3. **Follow component-specific documentation**

## Support

- **Issues**: Create GitHub issues for bugs or questions
- **Documentation**: Check component-specific README files
- **WALLIX Support**: Contact WALLIX for product questions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

Follow existing code structure and add documentation for new features.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

## Contributors ✨

Thanks goes to these wonderful people :

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/bsimonWallix"><img src="https://avatars.githubusercontent.com/u/130672981?v=4" width="100px;" alt=""/><br /><sub><b>bsimon-wallix</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/moulip"><img src="https://avatars.githubusercontent.com/u/805421?v=4" width="100px;" alt=""/><br /><sub><b>moulip</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/swcortetWALLIX"><img src="https://avatars.githubusercontent.com/u/190351850?v=4" width="100px;" alt=""/><br /><sub><b>swcortetWALLIX</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/shelleu-wallix"><img src="https://avatars.githubusercontent.com/u/148475813?v=4" width="100px;" alt=""/><br /><sub><b>Sébastien Helleu</b></sub></a></td>
    </tr>
  </tbody>
</table>



<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
Check the legend for the [emoji keys here](https://allcontributors.org/docs/en/emoji-key)

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
