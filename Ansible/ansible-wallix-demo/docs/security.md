# Security Measures

This project implements several security best practices to ensure that sensitive credentials retrieved from Wallix Bastion are handled securely within the CI/CD pipeline.

## 1. Secret Masking in Logs

The Ansible playbook uses `no_log: true` on sensitive tasks.

- **Retrieval Task:** The task that calls `wallix.pam_secret_action.secret` has logging disabled to prevent the retrieved password or SSH key from appearing in the job logs.
- **File Creation:** The task that writes the SSH key to a temporary file also has logging disabled.

## 2. Secure File Handling

We use a `block` and `always` structure in the playbook to ensure proper cleanup.

- **Temporary File:** The SSH key is written to a temporary file (e.g., `/tmp/ssh_key`) with restricted permissions (`0600`).
- **Guaranteed Cleanup:** The `always` section ensures that this temporary file is deleted at the end of the playbook execution, regardless of whether the deployment succeeded or failed.

## 3. CI/CD Variable Injection

Secrets are not hardcoded in the repository.

- **GitLab Variables:** Credentials like `WALLIX_URL`, `WALLIX_USER`, and `WALLIX_PASSWORD` are stored in GitLab CI/CD Settings.
- **Protection:** Critical variables are marked as **Protected** so they are only available in pipelines running on protected branches (e.g., `main`).
- **Masking:** Variables are marked as **Masked** so they are redacted in job logs.
    *   *Note:* GitLab has strict requirements for masked variables (min 8 chars, specific characters only). If a variable cannot be masked (e.g., contains `$`), it must be handled with extra care (like `no_log: true` in Ansible).

## 4. Least Privilege

The Wallix account used by the pipeline (`gilbert` in this demo) should have restricted permissions, allowing checkout only for the specific target accounts required by the automation.
