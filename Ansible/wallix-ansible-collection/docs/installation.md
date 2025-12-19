# Installation Guide

This guide describes how to install the Wallix Access Manager Ansible Collection.

## Prerequisites

* Ansible 2.9 or later
* Python 3.6 or later
* `requests` Python library

## Installation Methods

### 1. From Source (Development)

If you have cloned the repository locally:

1. Navigate to the collection root directory:

    ```bash
    cd wallix-ansible-collection
    ```

2. Build the collection artifact:

    ```bash
    ansible-galaxy collection build
    ```

    This will create a tarball, e.g., `wallix-pam_secret_action-1.0.1.tar.gz`.

3. Install the collection:

    ```bash
    ansible-galaxy collection install wallix-pam_secret_action-1.0.1.tar.gz
    ```

### 2. Using `requirements.yml` (Recommended for Projects)

To use this collection in your Ansible projects or Execution Environments, add it to your `requirements.yml` file.

**If hosted on a Git repository:**

```yaml
collections:
  - name: wallix.pam_secret_action
    source: https://github.com/your-org/wallix-ansible-collection.git
    type: git
    version: main
```

**If hosted on a Private Automation Hub:**

```yaml
collections:
  - name: wallix.pam_secret_action
    version: 1.0.0
```

Then install dependencies:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Execution Environment (AAP / OpenShift)

To use this collection within an Ansible Automation Platform (AAP) Execution Environment running on OpenShift:

1. Create an `execution-environment.yml` file:

    ```yaml
    version: 1
    build_arg_defaults:
      EE_BASE_IMAGE: 'registry.redhat.io/ansible-automation-platform-21/ee-supported-rhel8:latest'

    dependencies:
      galaxy:
        collections:
          - name: wallix.pam_secret_action
            source: https://github.com/your-org/wallix-ansible-collection.git
            type: git
      python:
        - requests

    additional_build_steps:
      prepend: |
        RUN pip install --upgrade pip
    ```

2. Build the image using `ansible-builder`:

    ```bash
    ansible-builder build -t my-registry/wallix-ee:latest
    ```

3. Push the image to your container registry:

    ```bash
    podman push my-registry/wallix-ee:latest
    ```

4. Configure AAP to use this image for your Job Templates.
