# Wallix Ansible Collection Examples

This directory contains templates and examples to help you get started with the Wallix Ansible Collection.

## Files

*   **`template_playbook.yml`**: A ready-to-use playbook template for testing the integration. It demonstrates:
    *   Checking out a credential (password or SSH key).
    *   Using the credential (saving SSH key to file).
    *   Checking in (releasing) the credential.

## Quick Start

1.  **Install the collection**:
    ```bash
    ansible-galaxy collection install git+https://github.com/wallix/ansible-collection.git
    ```

2.  **Export your Wallix credentials**:
    ```bash
    export WALLIX_URL="https://your-bastion.com"
    export WALLIX_USER="your-api-user"
    export WALLIX_PASSWORD="your-password"
    ```

3.  **Edit the template**:
    Open `template_playbook.yml` and adjust the `target_account`, `target_domain`, and `target_device` variables to match a real target in your Wallix Bastion.

4.  **Run the playbook**:
    ```bash
    ansible-playbook template_playbook.yml
    ```
