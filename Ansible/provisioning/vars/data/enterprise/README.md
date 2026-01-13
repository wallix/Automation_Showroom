# Enterprise Dataset

Large-scale enterprise provisioning data for WALLIX Bastion.

## Overview

This dataset represents a realistic enterprise environment with:
- **3 Environments**: Production, Staging, Development
- **2 Data Centers**: DC1-Paris (Prod/Staging), DC2-London (Dev)
- **Multiple Tiers**: Web, App, Database, Infrastructure
- **Role-based Access**: Department and function-based groups

## Dataset Statistics

| Category | Count | Description |
|----------|-------|-------------|
| **Devices** | 45+ | Servers across all environments |
| **Services** | 65+ | SSH, RDP, Database connections |
| **Accounts** | 50+ | Local and service accounts |
| **Target Groups** | 35+ | Environment, tier, and role-based |
| **User Groups** | 20+ | Department and function groups |
| **Users** | 40+ | IT, DevOps, Developers, Security |
| **Authorizations** | 30+ | Role-to-target mappings |
| **Timeframes** | 6 | Business, extended, 24/7, etc. |

## File Structure

```
enterprise/
├── infrastructure.yml    # Devices, services, accounts
├── target_groups.yml     # Target groups and mappings
├── domains.yml           # AD/LDAP domains, global accounts
├── users.yml             # User groups and users
└── authorizations.yml    # Authorizations and timeframes
```

## Infrastructure Layout

### Production Environment (10.1.x.x)
| Tier | Subnet | Servers |
|------|--------|---------|
| Web (DMZ) | 10.1.1.x | prod-web-01/02/03, prod-lb-01/02 |
| Application | 10.1.2.x | prod-app-01/02/03/04 |
| Database | 10.1.3.x | PostgreSQL, MySQL, Redis, Elastic |
| Windows | 10.1.4.x | Domain Controllers, File Server, SQL Server |
| Infrastructure | 10.1.5.x | Monitoring, Logging, Vault, Ansible |

### Staging Environment (10.2.x.x)
| Tier | Subnet | Servers |
|------|--------|---------|
| Combined | 10.2.x.x | stg-web-01, stg-app-01, stg-db-01/02, stg-win-01 |

### Development Environment (10.3.x.x)
| Tier | Subnet | Servers |
|------|--------|---------|
| Combined | 10.3.x.x | dev-web-01, dev-app-01/02, dev-db-01/02 |

### CI/CD Infrastructure (10.4.x.x)
| Service | IP | Description |
|---------|-----|-------------|
| cicd-jenkins-01 | 10.4.1.10 | Jenkins Master |
| cicd-gitlab-01 | 10.4.1.30 | GitLab Server |
| cicd-registry-01 | 10.4.1.40 | Docker Registry |
| cicd-sonar-01 | 10.4.1.50 | SonarQube |
| cicd-artifactory-01 | 10.4.1.60 | Artifactory |

### Security Infrastructure (10.5.x.x)
| Service | IP | Description |
|---------|-----|-------------|
| sec-siem-01 | 10.5.1.10 | SIEM Primary |
| sec-scanner-01 | 10.5.1.20 | Vulnerability Scanner |
| sec-av-01 | 10.5.1.30 | Antivirus Management |

### Network Devices (10.0.0.x)
| Device | IP | Description |
|--------|-----|-------------|
| net-fw-01/02 | 10.0.0.1/2 | Firewall HA pair |
| net-switch-core-01/02 | 10.0.0.10/11 | Core switches |

## User Groups & Roles

### IT Operations
| Group | Profile | Access |
|-------|---------|--------|
| IT_Infrastructure | user | All environments |
| DBAs | user | All databases |
| Network_Admins | user | Network devices |
| Security_Team | auditor | Audit/monitoring |
| SOC_Analysts | auditor | SIEM access |

### Development & DevOps
| Group | Profile | Access |
|-------|---------|--------|
| DevOps | user | CI/CD, non-prod |
| SRE | user | Prod infrastructure |
| Developers | user | Dev environment |
| Developers_Senior | user | Dev + Staging |
| QA_Team | user | Staging + Dev |

### External & Special
| Group | Profile | Access |
|-------|---------|--------|
| External_Contractors | user | Dev only (limited hours) |
| Vendors | user | Specific (approval required) |
| Emergency_Access | user | Break-glass (approval) |
| PAM_Admins | product_administrator | Full PAM access |

## Timeframes

| Name | Days | Hours | Use Case |
|------|------|-------|----------|
| TF_BUSINESS_HOURS | Mon-Fri | 8AM-6PM | Standard business |
| TF_EXTENDED_HOURS | Mon-Sat | 6AM-10PM | Operations |
| TF_ALWAYS | All | 24/7 | Critical access |
| TF_MAINTENANCE_WINDOW | Sat-Sun | 2AM-6AM | Maintenance |
| TF_NIGHT_SHIFT | All | 10PM-8AM | Night operations |
| TF_CONTRACTOR | Mon-Fri | 9AM-5PM | External access |

## Usage

### Provision Enterprise Environment

```bash
# Interactive (with confirmation)
make enterprise

# Quick (no confirmation)
make enterprise-quick

# Or manually with specific options
ansible-playbook playbooks/enterprise-provision.yml \
  -e wallix_bastion_host=10.10.122.15 \
  -e wallix_bastion_port=443 \
  --vault-password-file /tmp/.vault_pass -vv
```

### Cleanup Enterprise Resources

```bash
# Interactive cleanup (requires confirmation)
make cleanup-enterprise

# Or dry-run first
make cleanup-dry-run
```

### Selective Provisioning

```bash
# Only infrastructure (devices, services, accounts)
ansible-playbook playbooks/enterprise-provision.yml \
  -e @vars/data/enterprise/infrastructure.yml \
  -e provision_user_groups=false \
  -e provision_users=false \
  -e provision_authorizations=false \
  --vault-password-file /tmp/.vault_pass

# Only users and authorizations
ansible-playbook playbooks/enterprise-provision.yml \
  -e @vars/data/enterprise/users.yml \
  -e @vars/data/enterprise/authorizations.yml \
  -e provision_devices=false \
  --vault-password-file /tmp/.vault_pass
```

## Customization

### Add New Servers

Edit `infrastructure.yml`:

```yaml
wallix_devices:
  - name: "prod-new-server"
    host: "10.1.2.99"
    description: "New Production Server"
    state: present
```

### Add New Team

Edit `users.yml`:

```yaml
wallix_user_groups:
  - name: "NewTeam"
    description: "New Team Description"
    profile: "user"
    state: present

wallix_users:
  - name: "team_member1"
    display_name: "Team Member 1"
    email: "member1@enterprise.com"
    groups:
      - "NewTeam"
    state: present
```

### Add New Authorization

Edit `authorizations.yml`:

```yaml
wallix_authorizations:
  - name: "AUTH_NEWTEAM_ACCESS"
    description: "NewTeam - Specific Access"
    user_group: "NewTeam"
    target_group: "TG_TARGET"
    is_critical: false
    is_recorded: true
    approval_required: false
    timeframes:
      - "TF_BUSINESS_HOURS"
    state: present
```

## Comparison with Demo Dataset

| Feature | Demo | Enterprise |
|---------|------|------------|
| Devices | 6 | 45+ |
| Environments | 1 | 3 (Prod/Stg/Dev) |
| User Groups | 5 | 20+ |
| Users | 7 | 40+ |
| Target Groups | 4 | 35+ |
| Authorizations | 7 | 30+ |
| Time Restrictions | Basic | 6 timeframes |
| LDAP/AD Integration | No | Yes (configured) |
| Emergency Access | No | Break-glass |
| Approval Workflows | No | Prepared |
| Provisioning Time | ~2 min | ~15 min |
