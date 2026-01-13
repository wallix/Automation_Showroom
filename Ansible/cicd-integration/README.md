# GitLab CI/CD + Ansible + WALLIX Integration

This project demonstrates secure integration between **GitLab CI/CD**, **Ansible Automation Platform**, and **WALLIX Bastion**. It shows how to retrieve secrets (passwords or SSH keys) just-in-time from WALLIX Bastion to perform automated deployment tasks.

## Overview

```text
GitLab CI/CD → Ansible Runner → WALLIX Bastion → Target Server
                    ↓
              Fetch SSH Key (JIT)
                    ↓
              Deploy to Target
```

## Project Structure

```text
.
├── .gitlab-ci.yml          # GitLab CI/CD pipeline definition
├── playbook.yml            # Ansible playbook for deployment
├── requirements.yml        # Ansible Galaxy dependencies
├── setup-gitlab-vars.sh    # Helper script for CI/CD variables
├── docs/
│   └── security.md         # Security implementation details
└── README.md
```

## Prerequisites

| Component      | Requirement                                             |
| -------------- | ------------------------------------------------------- |
| GitLab         | Instance with CI/CD enabled                             |
| GitLab Runner  | Kubernetes/OpenShift runner with `ansible-runner` image |
| WALLIX Bastion | API access with valid credentials                       |
| Target Server  | Managed by WALLIX Bastion                               |

## Quick Start

### 1. Prepare GitLab Project

1. Create a new blank project in GitLab
2. Generate a Project Access Token with `api` scope:
   - Go to **Settings > Access Tokens**
   - Role: `Maintainer`
   - Scopes: `api`

### 2. Get the Code

```bash
# Clone this demo
git clone https://github.com/wallix/Automation_Showroom.git
cd Automation_Showroom/Ansible/cicd-integration

# Push to your GitLab project
git remote add gitlab <your-gitlab-project-url>
git push gitlab main
```

### 3. Configure Secrets

Use the helper script to configure CI/CD variables:

```bash
# Set your GitLab token
export PRIVATE_TOKEN=glpat-xxxxxxxxxxxxxxxxx

# Edit credentials in the script
vim setup-gitlab-vars.sh

# Run the script
./setup-gitlab-vars.sh
```

### 4. Run the Pipeline

1. Go to **Build > Pipelines** in GitLab
2. Click **Run pipeline**
3. Select `main` branch and run

## Pipeline Workflow

1. **Install Dependencies** - Fetch `wallix.pam` collection
2. **Fix Environment** - Adjust OpenShift UID permissions
3. **Run Playbook**:
   - Retrieve SSH key from WALLIX (no logging)
   - Save to temporary file
   - Connect to target server
   - Execute deployment tasks
   - Clean up temporary key file

## Configuration

### CI/CD Variables

| Variable          | Description  | Protected | Masked |
| ----------------- | ------------ | --------- | ------ |
| `WALLIX_URL`      | Bastion URL  | Yes       | No     |
| `WALLIX_USER`     | API username | Yes       | No     |
| `WALLIX_PASSWORD` | API password | Yes       | Yes    |

### Ansible Collection

The `wallix.pam` collection is installed automatically via `requirements.yml`:

```yaml
collections:
  - name: https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
    type: git
    version: main
```

## Troubleshooting

### Pipeline Fails at Secret Retrieval

- Verify WALLIX credentials are correct
- Check API user has permission for the target account
- Verify target format: `account@domain@device`

### Runner Permission Errors

Add UID fix step in pipeline:

```yaml
before_script:
  - export HOME=/tmp
```

### Collection Not Found

Ensure `requirements.yml` is in project root and contains valid collection reference.

## Security

- Secrets retrieved just-in-time (not stored in GitLab)
- Temporary key files cleaned up automatically
- All secret operations use `no_log: true`
- See [docs/security.md](docs/security.md) for details

## Requirements

| Component      | Version |
| -------------- | ------- |
| Ansible Core   | ≥ 2.15  |
| Python         | ≥ 3.9   |
| WALLIX Bastion | ≥ 10.0  |
| GitLab         | ≥ 14.0  |

## See Also

- [wallix-ansible-collection](../wallix-ansible-collection/) - Core collection
- [Security Documentation](docs/security.md) - Security implementation

## License

MPL-2.0 (Mozilla Public License 2.0) - See [LICENSE](../../LICENSE)
