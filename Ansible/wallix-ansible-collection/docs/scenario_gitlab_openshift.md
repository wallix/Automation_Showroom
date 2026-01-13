# Integration Scenario: GitLab CI/CD + OpenShift + WALLIX

This guide describes a secure CI/CD workflow where GitLab CI running on OpenShift uses Ansible to deploy applications, retrieving credentials from WALLIX Bastion just-in-time.

## 🏗️ Architecture Overview

```text
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   GitLab CI     │────▶│   OpenShift     │────▶│  WALLIX Bastion │
│   (Pipeline)    │     │   (Runner Pod)  │     │  (Credentials)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │ Target Servers  │
                        │ (Deployment)    │
                        └─────────────────┘
```

### Components

| Component          | Role                                               |
| ------------------ | -------------------------------------------------- |
| **GitLab CI**      | Orchestrates the pipeline, stores masked variables |
| **OpenShift**      | Hosts GitLab Runner pods, executes CI jobs         |
| **Ansible Runner** | Containerized execution environment for playbooks  |
| **WALLIX Bastion** | Securely stores and manages credentials            |
| **Target Servers** | Deployment destinations                            |

## 📋 Workflow Steps

### 1. Pipeline Trigger

Developer pushes code → GitLab CI pipeline starts

### 2. Environment Preparation

- GitLab Runner spawns pod on OpenShift
- Injects `WALLIX_URL`, `WALLIX_USER`, `WALLIX_PASSWORD` as **masked** and **protected** variables

### 3. Secret Retrieval (Just-in-Time)

- Ansible playbook calls `wallix.pam.secret` module
- Credentials retrieved only for job duration
- All operations logged with `no_log: true`

### 4. Deployment

- Ansible uses retrieved SSH key to connect to targets
- Deployment tasks execute
- Secrets never written to logs

### 5. Cleanup

- `always` block ensures temporary files are deleted
- Credentials automatically expire if not checked in

## 🔧 Configuration Examples

### GitLab CI Configuration

**`.gitlab-ci.yml`:**

```yaml
stages:
  - deploy

variables:
  ANSIBLE_HOST_KEY_CHECKING: "False"
  ANSIBLE_STDOUT_CALLBACK: yaml

deploy_application:
  stage: deploy
  image: quay.io/ansible/ansible-runner:latest
  
  before_script:
    - pip install --quiet requests
    - ansible-galaxy collection install -r requirements.yml
  
  script:
    - ansible-playbook playbooks/deploy.yml
  
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: always
  
  environment:
    name: production
```

**`requirements.yml`:**

```yaml
---
collections:
  - name: https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
    type: git
    version: main
```

### Ansible Playbook

**`playbooks/deploy.yml`:**

```yaml
---
- name: Retrieve Credentials from WALLIX
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    ssh_key_path: "/tmp/deploy_key_{{ ansible_date_time.epoch }}"

  tasks:
    - name: Checkout SSH Key from WALLIX
      wallix.pam.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "ansible"
        domain: "local"
        device: "{{ target_server | default('production-server') }}"
        state: checkout
        validate_certs: true
      register: wallix_secret
      no_log: true

    - name: Save SSH Key securely
      ansible.builtin.copy:
        content: "{{ wallix_secret.ssh_key }}"
        dest: "{{ ssh_key_path }}"
        mode: '0600'
      no_log: true

    - name: Set SSH key path for deployment
      ansible.builtin.set_fact:
        ansible_ssh_private_key_file: "{{ ssh_key_path }}"

- name: Deploy Application
  hosts: production
  gather_facts: true

  tasks:
    - name: Ensure application directory exists
      ansible.builtin.file:
        path: /opt/myapp
        state: directory
        mode: '0755'

    - name: Deploy application files
      ansible.builtin.copy:
        src: ../dist/
        dest: /opt/myapp/
        mode: '0644'

    - name: Restart application service
      ansible.builtin.systemd:
        name: myapp
        state: restarted
        enabled: true

- name: Cleanup
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Remove temporary SSH key
      ansible.builtin.file:
        path: "{{ ssh_key_path }}"
        state: absent
      ignore_errors: true

    - name: Checkin credentials
      wallix.pam.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "ansible"
        device: "{{ target_server | default('production-server') }}"
        state: checkin
        force: true
        comment: "GitLab pipeline completed"
      ignore_errors: true
```

### GitLab Variables Configuration

In **Settings → CI/CD → Variables**, add:

| Variable          | Value                         | Protected | Masked |
| ----------------- | ----------------------------- | --------- | ------ |
| `WALLIX_URL`      | `https://bastion.example.com` | ✅        | ❌     |
| `WALLIX_USER`     | `svc_gitlab_cicd`             | ✅        | ❌     |
| `WALLIX_PASSWORD` | `(your-password)`             | ✅        | ✅     |

## 🔒 Security Best Practices

### Identity & Access Management

| Practice                      | Implementation                                        |
| ----------------------------- | ----------------------------------------------------- |
| **Dedicated Service Account** | Create `svc_gitlab_cicd` user in WALLIX               |
| **Least Privilege**           | Grant only "Checkout" permission on required accounts |
| **IP Restriction**            | Limit API access to OpenShift egress IPs              |
| **Short Session Duration**    | Set minimal checkout duration                         |

### Pipeline Security

```yaml
# ✅ Use protected branches
rules:
  - if: $CI_COMMIT_BRANCH == "main"

# ✅ Use protected environments
environment:
  name: production
```

### Playbook Hardening

```yaml
# ✅ Mandatory no_log
- name: Handle secret
  wallix.pam.secret:
    # ...
  no_log: true

# ✅ Guaranteed cleanup with block/always
- block:
    - name: Use secret
      # ...
  always:
    - name: Cleanup
      ansible.builtin.file:
        path: /tmp/key
        state: absent

# ✅ SSL validation in production
validate_certs: true
```

### Network Security

| Control               | Description                      |
| --------------------- | -------------------------------- |
| **HTTPS Only**        | Never use HTTP for WALLIX API    |
| **NetworkPolicies**   | Restrict Runner namespace egress |
| **Private Endpoints** | Use internal DNS where possible  |

## ✅ Security Benefits Summary

| Benefit                    | Description                             |
| -------------------------- | --------------------------------------- |
| **Zero Hardcoded Secrets** | No credentials in git repositories      |
| **Ephemeral Access**       | Credentials exist only for job duration |
| **Complete Audit Trail**   | WALLIX logs all access with timestamps  |
| **Leak Prevention**        | GitLab masking + Ansible `no_log`       |
| **Automated Cleanup**      | Temporary files removed automatically   |

## 📖 Related Documentation

- [Installation Guide](installation.md)
- [Examples](../examples/)
- [WALLIX Bastion API Documentation](https://docs.wallix.com)
