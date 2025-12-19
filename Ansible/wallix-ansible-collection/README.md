# Wallix PAM Secret Action Collection

This collection provides modules and plugins to integrate Wallix Access Manager with Ansible Automation Platform.

## Content

* **Modules**:
  * `secret`: Retrieve passwords and SSH keys from the Wallix Bastion.
* **Lookup Plugins**:
  * `secret`: Retrieve secrets inline within playbooks.

## Installation

### Using Ansible Galaxy (requirements.yml)

The most common way to manage collections in production or CI/CD pipelines is using a `requirements.yml` file.

1. Create a `requirements.yml` file in your project root:

    ```yaml
    ---
    collections:
      # Install directly from the Git repository
      - name: https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
        type: git
        version: main
    ```

2. Install the collection:

    ```bash
    ansible-galaxy collection install -r requirements.yml
    ```

    *Note: If you are using Ansible Automation Platform (AAP) or AWX, simply include this `requirements.yml` in your project's root directory, and the system will automatically install it before running jobs.*

### Installing Manually from Git

You can install the collection directly from the command line without a requirements file:

```bash
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
```

### Installing from Source (Local Build)

If you are developing the collection or need to install from a local folder:

1. Clone the repository:

    ```bash
    git clone https://github.com/wallix/ansible-collection.git
    cd ansible-collection
    ```

2. Build the collection artifact:

    ```bash
    ansible-galaxy collection build
    # This creates a file named wallix-pam_secret_action-1.0.1.tar.gz
    ```

3. Install the artifact:

    ```bash
    ansible-galaxy collection install wallix-pam_secret_action-1.0.1.tar.gz
    ```

## Usage Examples

### 1. Basic Playbook with Module

This example shows how to retrieve credentials using the module task. This is useful when you need to register the secret to a variable for use in multiple subsequent tasks.

```yaml
---
- hosts: localhost
  connection: local
  vars:
    # Best Practice: Pass these as extra_vars or environment variables
    wallix_url: "https://bastion.example.com"
    wallix_user: "service-user"
    wallix_password: "service-password"

  tasks:
    - name: Checkout SSH Key for Target Server
      wallix.pam_secret_action.secret:
        wallix_url: "{{ wallix_url }}"
        username: "{{ wallix_user }}"
        password: "{{ wallix_password }}"
        account: "root"
        domain: "local"
        device: "target-server-01"
        state: checkout
        validate_certs: no
      register: wallix_secret
      no_log: true # CRITICAL: Always hide secrets from logs!

    - name: Use the retrieved key
      debug:
        msg: "Retrieved SSH key for user {{ wallix_secret.login }}"
```

### 2. Using the Lookup Plugin (Inline)

The lookup plugin allows you to fetch secrets "just-in-time" within a task parameter. It supports reading configuration from environment variables, which is ideal for CI/CD pipelines.

**Environment Variables:**

* `WALLIX_API_URL`
* `WALLIX_API_USER`
* `WALLIX_API_PASSWORD`

**Playbook:**

```yaml
---
- hosts: webservers
  tasks:
    - name: Deploy Application with DB Password
      ansible.builtin.template:
        src: config.j2
        dest: /etc/app/config.ini
      vars:
        # Format: account@domain@device
        db_password: "{{ lookup('wallix.pam_secret_action.secret', 'app-user@local@db-server-01') }}"
```

### 3. Dynamic Inventory Integration

You can use the collection to dynamically fetch SSH keys for your inventory hosts.

```yaml
- hosts: all
  gather_facts: no
  vars:
    # Configure connection to use the retrieved key
    ansible_ssh_private_key_file: "/tmp/ssh_key_{{ inventory_hostname }}"
  
  pre_tasks:
    - name: Fetch SSH Key from Wallix
      delegate_to: localhost
      wallix.pam_secret_action.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "ansible"
        domain: "local"
        device: "{{ inventory_hostname }}" # Matches the host in inventory
        state: checkout
      register: host_secret
      no_log: true

    - name: Save Key to Temporary File
      delegate_to: localhost
      copy:
        content: "{{ host_secret.ssh_key }}"
        dest: "{{ ansible_ssh_private_key_file }}"
        mode: '0600'
      no_log: true

  tasks:
    - name: Ping Target
      ping:

  post_tasks:
    - name: Cleanup Key File
      delegate_to: localhost
      file:
        path: "{{ ansible_ssh_private_key_file }}"
        state: absent
      ignore_errors: yes
```

### 4. Advanced Usage: Checkin and Extend

The module supports managing the lifecycle of the secret checkout.

**Checkin (Release Secret):**
If you want to explicitly release a secret back to the vault before the duration expires (e.g., in a `always` block).

```yaml
- name: Release the secret (Checkin)
  wallix.pam_secret_action.secret:
    wallix_url: "{{ wallix_url }}"
    username: "{{ wallix_user }}"
    password: "{{ wallix_password }}"
    account: "admin"
    device: "prod-db-01"
    state: checkin
    # Optional: Force checkin with comment
    # force: true
    # comment: "Deployment finished"
```

**Extend (Renew Checkout):**
If a long-running task needs more time with the secret.

```yaml
- name: Extend checkout duration
  wallix.pam_secret_action.secret:
    wallix_url: "{{ wallix_url }}"
    username: "{{ wallix_user }}"
    password: "{{ wallix_password }}"
    account: "admin"
    device: "prod-db-01"
    state: extend
```

## Requirements

* Python 3.6+
* `requests` library
