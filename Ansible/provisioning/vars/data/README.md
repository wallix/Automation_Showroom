# Data Directory Structure

This directory contains provisioning data organized by dataset and templates.

```text
vars/data/
├── demo/                    # Demo/testing dataset
│   ├── cleanup_patterns.yml # Cleanup patterns for demo resources
│   ├── infrastructure.yml   # Devices, services, local accounts
│   └── users.yml            # Domains, users, groups, authorizations
│
├── enterprise/              # Enterprise-scale dataset
│   ├── cleanup_patterns.yml # Cleanup patterns for enterprise resources
│   ├── infrastructure.yml   # 49 devices, 59 services, 49 accounts
│   ├── target_groups.yml    # 35 target groups
│   ├── domains.yml          # 4 domains, 7 global accounts
│   ├── users.yml            # 18 user groups, 40 users
│   ├── authorizations.yml   # 32 authorizations, 6 timeframes
│   └── README.md            # Enterprise dataset documentation
│
└── templates/               # Reusable templates for new resources
    ├── device-template.yml
    ├── user-template.yml
    ├── domain-template.yml
    ├── authorization-template.yml
    ├── example-server.yml
    ├── example-user.yml
    └── example-domain.yml
```

## Usage

### Demo Dataset

```bash
make demo              # Provision demo environment
make cleanup-demo      # Remove demo resources
```

### Enterprise Dataset

```bash
make enterprise        # Provision enterprise environment
make cleanup-enterprise # Remove enterprise resources
```

### Custom Resources

Copy a template from `templates/` and customize:

```bash
cp templates/device-template.yml my-server.yml
# Edit my-server.yml
ansible-playbook playbooks/core/provision-incremental.yml -e @my-server.yml
```

## Creating New Datasets

1. Create a new folder: `mkdir vars/data/myproject/`
2. Copy and adapt files from `demo/` or `enterprise/`
3. Create cleanup patterns: `cleanup_patterns.yml`
4. Add Makefile targets if needed
