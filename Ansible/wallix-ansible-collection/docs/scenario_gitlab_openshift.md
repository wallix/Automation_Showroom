# Integration Scenario: GitLab CI/CD + OpenShift + Wallix

This document describes a secure CI/CD workflow where GitLab CI running on OpenShift uses Ansible Runner to deploy applications, securely retrieving credentials from Wallix Bastion just-in-time.

## Architecture Overview

1. **GitLab CI**: Orchestrates the pipeline.
2. **OpenShift**: Hosts the GitLab Runner and executes the CI jobs.
3. **Ansible Runner**: A containerized execution environment that runs the Ansible Playbooks.
4. **Wallix Bastion (PAM)**: Securely stores and manages access credentials (SSH keys, passwords).
5. **Target Server**: The destination for the deployment.

## Workflow Steps

### 1. Pipeline Trigger

A developer pushes code to the GitLab repository, triggering the CI/CD pipeline defined in `.gitlab-ci.yml`.

### 2. Environment Preparation

The GitLab Runner on OpenShift starts a pod using the `ansible-runner` image.

* **Secure Variables**: GitLab injects sensitive connection details (`WALLIX_URL`, `WALLIX_USER`, `WALLIX_PASSWORD`) as **Masked** and **Protected** environment variables. These are never stored in the repository.

### 3. Secret Retrieval (Just-in-Time)

The Ansible Playbook executes the `wallix.pam_secret_action` collection.

* It connects to the Wallix Bastion API.
* It requests a checkout of the specific credential needed for the target (e.g., an SSH key).
* **Security**: The retrieved secret is registered with `no_log: true` to prevent it from appearing in job logs.

### 4. Deployment

Ansible uses the retrieved SSH key to connect to the target server through the Wallix Bastion (or directly, depending on network topology) and performs the deployment tasks.

### 5. Cleanup

Using Ansible's `block/always` pattern, the temporary SSH key file is securely deleted from the runner container immediately after the playbook finishes, regardless of success or failure.

## Configuration Example

### .gitlab-ci.yml

```yaml
deploy_app:
  stage: deploy
  image: quay.io/ansible/ansible-runner:latest
  variables:
    ANSIBLE_HOST_KEY_CHECKING: "False"
  script:
    - ansible-galaxy collection install git+https://github.com/wallix/ansible-collection.git
    - ansible-playbook playbook.yml
```

### playbook.yml

```yaml
- hosts: localhost
  tasks:
    - name: Retrieve SSH Key from Wallix
      wallix.pam_secret_action.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "ansible"
        domain: "local"
        device: "target-server"
        state: checkout
        validate_certs: no
      register: wallix_secret
      no_log: true

    - name: Save SSH Key to file
      copy:
        content: "{{ wallix_secret.ssh_key }}"
        dest: "/tmp/ssh_key"
        mode: '0600'
      no_log: true

- hosts: all
  vars:
    ansible_ssh_private_key_file: "/tmp/ssh_key"
  tasks:
    - name: Deploy Application
      # ... deployment tasks ...
```

## Security Best Practices

To ensure a production-grade secure implementation, follow these guidelines:

### 1. Identity & Access Management (IAM)

* **Dedicated Service Account**: Create a specific API user in Wallix for the CI/CD pipeline (e.g., `svc_gitlab_cicd`).
* **Least Privilege**: Grant this user *only* the "Checkout" permission on the specific target accounts required for the deployment. Do not grant "Connect" or administrative rights.
* **IP Restriction**: If possible, configure Wallix to accept API requests for this user only from the OpenShift cluster's egress IP.

### 2. Pipeline Configuration

* **Protected Variables**: In GitLab, mark `WALLIX_PASSWORD` and `WALLIX_API_KEY` as **Protected**. This ensures they are only exposed to pipelines running on protected branches (like `main` or `production`).
* **Masked Variables**: Always mark these variables as **Masked** to prevent accidental leakage in job logs.
* **Environment Scoping**: Use GitLab Environments to scope variables. For example, the `production` environment might use a different Wallix user/password than `staging`.

### 3. Playbook Hardening

* **Mandatory `no_log`**: Ensure `no_log: true` is present on the `wallix.pam_secret_action.secret` task and any `copy` task handling the key.
* **Guaranteed Cleanup**: Always use `block`, `rescue`, and `always` sections. The file deletion task must be in the `always` section to run even if the deployment fails.
* **TLS Validation**: In production, set `validate_certs: yes`. You may need to add your internal CA certificate to the Ansible Runner image or mount it as a ConfigMap if needed.

### 4. Network Security

* **HTTPS Only**: Never use HTTP for the Wallix API endpoint.
* **Network Policies**: Use OpenShift NetworkPolicies to restrict the GitLab Runner namespace so it can *only* communicate with the Wallix Bastion and the specific target subnets.

## Security Benefits

* **Zero Hardcoded Secrets**: No credentials in git repositories.
* **Ephemeral Access**: Credentials exist only for the duration of the job.
* **Audit Trail**: Wallix logs exactly which CI job accessed which credential and when.
* **Leak Prevention**: GitLab masking and Ansible `no_log` prevent accidental exposure in logs.
