# Installation Guide

This guide covers all installation methods for the **WALLIX PAM Ansible Collection**.

## Prerequisites

| Component      | Minimum Version | Notes                                    |
| -------------- | --------------- | ---------------------------------------- |
| Ansible Core   | 2.15+           | Older versions may work but are untested |
| Python         | 3.9+            | Required on control node                 |
| `requests`     | Latest          | Install via pip                          |
| WALLIX Bastion | 10.0+           | API access required                      |

### Install Python Dependencies

```bash
pip install requests
```

## Installation Methods

### Method 1: Using requirements.yml (Recommended)

This is the preferred method for production environments and CI/CD pipelines.

**Create `requirements.yml`:**

```yaml
---
collections:
  - name: https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
    type: git
    version: main  # or a specific tag/commit
```

**Install:**

```bash
ansible-galaxy collection install -r requirements.yml
```

### Method 2: Direct CLI Installation

Install directly without a requirements file:

```bash
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
```

### Method 3: From Source (Development)

For contributing or local development:

```bash
# Clone the repository
git clone https://github.com/wallix/Automation_Showroom.git
cd Automation_Showroom/Ansible/wallix-ansible-collection

# Build the collection tarball
ansible-galaxy collection build

# Install locally
ansible-galaxy collection install wallix-pam-*.tar.gz
```

### Method 4: Private Automation Hub

If publishing to a private Automation Hub:

```yaml
# requirements.yml
collections:
  - name: wallix.pam
    version: ">=1.0.0"
```

Configure your `ansible.cfg`:

```ini
[galaxy]
server_list = automation_hub

[galaxy_server.automation_hub]
url=https://hub.example.com/api/galaxy/
token=YOUR_TOKEN
```

## Platform-Specific Installation

### Ansible Automation Platform (AAP) / AWX

Include `requirements.yml` in your project root. Collections install automatically before job execution.

**Project structure:**

```text
my-project/
├── requirements.yml      # Collection dependencies
├── playbooks/
│   └── deploy.yml
└── inventories/
    └── production.yml
```

### Execution Environment (OpenShift/Kubernetes)

Build a custom Execution Environment with the collection pre-installed.

**`execution-environment.yml`:**

```yaml
version: 3

images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel9:latest

dependencies:
  galaxy: requirements.yml
  python: requirements.txt
  system: bindep.txt

additional_build_steps:
  prepend_galaxy:
    - ADD requirements.yml /tmp/requirements.yml
```

**`requirements.txt`:**

```text
requests>=2.28.0
```

**Build with ansible-builder:**

```bash
# Install ansible-builder
pip install ansible-builder

# Build the image
ansible-builder build -t my-registry/wallix-ee:latest

# Push to registry
podman push my-registry/wallix-ee:latest
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
deploy:
  image: quay.io/ansible/ansible-runner:latest
  before_script:
    - pip install requests
    - ansible-galaxy collection install -r requirements.yml
  script:
    - ansible-playbook playbooks/deploy.yml
```

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          pip install ansible requests
          ansible-galaxy collection install -r requirements.yml
      
      - name: Run playbook
        env:
          WALLIX_URL: ${{ secrets.WALLIX_URL }}
          WALLIX_USER: ${{ secrets.WALLIX_USER }}
          WALLIX_PASSWORD: ${{ secrets.WALLIX_PASSWORD }}
        run: ansible-playbook playbooks/deploy.yml
```

## Verify Installation

```bash
# List installed collections
ansible-galaxy collection list | grep wallix

# Expected output:
# wallix.pam    1.0.1

# Test module availability
ansible-doc wallix.pam.secret
```

## Upgrading

```bash
# Force reinstall to upgrade
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection --force

# Or with requirements.yml
ansible-galaxy collection install -r requirements.yml --force
```

## Uninstallation

```bash
# Find installation path
ansible-galaxy collection list wallix.pam

# Remove the collection directory
rm -rf ~/.ansible/collections/ansible_collections/wallix/pam
```

## Next Steps

- Review the [README](../README.md) for usage examples
- Check [examples/](../examples/) for ready-to-use playbooks
- See [scenario_gitlab_openshift.md](scenario_gitlab_openshift.md) for CI/CD integration

1. Configure AAP to use this image for your Job Templates.
