# GitLab CI/CD + Ansible + Wallix Integration Demo

This project demonstrates a secure integration between **GitLab CI/CD**, **Ansible Automation Platform**, and **Wallix Bastion**. It shows how to retrieve secrets (passwords or SSH keys) just-in-time from a Wallix Bastion to perform automated deployment tasks on a target server.

## Project Structure

```txt
.
├── .gitlab-ci.yml          # GitLab CI/CD pipeline definition
├── playbook.yml            # Ansible playbook for deployment
├── requirements.yml        # Ansible Galaxy dependencies (Wallix collection)
├── setup-gitlab-vars.sh    # Helper script to configure GitLab CI/CD variables
├── docs/                   # Documentation
│   └── security.md         # Details on security measures implemented
└── README.md               # This file
```

## Prerequisites

*   **GitLab Instance:** You need access to a GitLab instance (SaaS or Self-Managed).
*   **GitLab Runner:** A runner deployed on OpenShift/Kubernetes (using `quay.io/ansible/ansible-runner` image) to execute the jobs.
*   **Wallix Bastion:** Access to a Wallix Bastion instance with an API account.
*   **Target Server:** A server managed by the Wallix Bastion (e.g., `ansible@local@DEBIAN`).

## 🚀 Quick Start Guide

Follow these steps to get the demo running in minutes.

### 1. Prepare your GitLab Project
1.  Create a **new blank project** in your GitLab instance.
2.  Generate a **Project Access Token** (or use your Personal Access Token) with `api` scope.
    *   Go to **Settings > Access Tokens**.
    *   Role: `Maintainer`.
    *   Scopes: `api`.
    *   Copy the token value.

### 2. Get the Code
Clone this repository and push it to your new GitLab project.

```bash
# Clone this demo
git clone https://github.com/wallix/Automation_Showroom.git ansible-wallix-demo
cd ansible-wallix-demo

# Point to your new GitLab project
git remote set-url origin <your-new-gitlab-project-url>
git push -u origin main
```

### 3. Configure Secrets
Use the provided helper script to securely configure your CI/CD variables.

1.  Edit `setup-gitlab-vars.sh` to set your Wallix credentials (`WALLIX_URL`, `WALLIX_USER`, `WALLIX_PASSWORD`) and your GitLab Project ID.
2.  Run the script with your token:

```bash
export PRIVATE_TOKEN=glpat-xxxxxxxxxxxxxxxxx
./setup-gitlab-vars.sh
```

> **Note:** The script will attempt to set variables as **Protected** and **Masked**.

### 4. Run the Pipeline
1.  Go to **Build > Pipelines** in GitLab.
2.  Click **Run pipeline**.
3.  Select the `main` branch and run.

The pipeline will:
1.  **Install Dependencies:** Fetch the `wallix.pam_secret_action` collection.
2.  **Fix Environment:** Adjust OpenShift UID permissions.
3.  **Run Playbook:**
    *   Retrieve the SSH key from Wallix (securely, no logs).
    *   Save it to a temporary file.
    *   Connect to the target server.
    *   Execute the deployment tasks.
    *   **Always** clean up the temporary key file.

## Configuration Details

### CI/CD Variables

The following variables are required for the pipeline to function. They are configured automatically by `setup-gitlab-vars.sh`:

*   `WALLIX_URL`: URL of the Wallix Bastion.
*   `WALLIX_USER`: API User.
*   `WALLIX_PASSWORD`: API Password.

### Ansible Collection

The project uses the `wallix.pam_secret_action` collection. It is installed automatically by the pipeline based on `requirements.yml`.



## Security

See [docs/security.md](docs/security.md) for details on how secrets are protected during execution.
