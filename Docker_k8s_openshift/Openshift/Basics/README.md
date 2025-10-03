# WALLIX to OpenShift Secret Management

This folder contains a bash script to transfer secrets from WALLIX Bastion to OpenShift.

#### 3. With Custom Namespace

```bash
# Create the secret in the 'production' namespace
WALLIX_PASSWORD=mypass ./pull_secret_to_vault.sh -n production admin@webserver@corp
```

#### 4. Dry-Run Mode

```bash
# See what would be done without executing (with prompt)
./pull_secret_to_vault.sh -d -v postgres@dbserver@local
```

#### 5. Advanced Configuration from WALLIX Bastion API to OpenShift secrets

## Available Scripts

### `pull_secret_to_vault.sh`

Main script that retrieves passwords from WALLIX Bastion and creates them as OpenShift secrets.

## Features

- ✅ Automatic authentication with WALLIX Bastion API v3.12
- ✅ **Secure password prompt** (if not provided via environment variable)
- ✅ Secure password retrieval via API
- ✅ Automatic creation of OpenShift secrets
- ✅ Support for custom namespaces
- ✅ Dry-run mode for testing without execution
- ✅ Error handling and automatic cleanup
- ✅ Detailed logs and verbose mode

## Prerequisites

### Required Tools

```bash
# OpenShift CLI
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
sudo mv oc /usr/local/bin/

# jq for JSON parsing (optional but recommended)
sudo apt-get install jq   # Ubuntu/Debian
sudo yum install jq       # RHEL/CentOS
```

### OpenShift Connection

```bash
# Connect to your OpenShift cluster
oc login https://your-openshift-cluster.com:6443 --username=your-user
```

## Usage

### Basic Syntax

```bash
# Option 1: Interactive prompt for password
./pull_secret_to_vault.sh ACCOUNT_SPECIFIER

# Option 2: Using environment variable
WALLIX_PASSWORD=your_password ./pull_secret_to_vault.sh ACCOUNT_SPECIFIER
```

**ACCOUNT_SPECIFIER format**: `account@target@domain` (e.g., `root@local@debian`)

### Password Management

The script supports two methods for providing the WALLIX password:

1. **Interactive prompt** (recommended for manual use):

  ```bash
  ./pull_secret_to_vault.sh root@local@debian
  # The script will securely prompt for the password
  ```

2. **Environment variable** (recommended for automation):

  ```bash
  WALLIX_PASSWORD=mypass ./pull_secret_to_vault.sh root@local@debian
  ```

### Usage Examples

#### 1. Simple Transfer with Prompt

```bash
# The script will securely prompt for the password
./pull_secret_to_vault.sh root@local@debian
```

#### 2. Simple Transfer with Environment Variable

```bash
# Retrieve the root password on the local debian server
WALLIX_PASSWORD=mypass ./pull_secret_to_vault.sh root@local@debian
```

#### 3. With Custom Namespace

```bash
# Create the secret in the 'production' namespace
WALLIX_PASSWORD=mypass ./pull_secret_to_vault.sh -n production admin@webserver@corp
```

#### 3. Dry-Run Mode

```bash
# See what would be done without executing
WALLIX_PASSWORD=mypass ./pull_secret_to_vault.sh -d -v postgres@dbserver@local
```

#### 4. Advanced Configuration

```bash
# With custom configuration
WALLIX_HOST=bastion.company.com \
WALLIX_USERNAME=admin \
WALLIX_PASSWORD=secret123 \
OPENSHIFT_NAMESPACE=my-app \
./pull_secret_to_vault.sh -v -p myapp oracle@dbcluster@prod
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|--------|
| `WALLIX_HOST` | WALLIX Bastion hostname/IP | `192.168.1.75` |
| `WALLIX_PORT` | WALLIX Bastion port | `443` |
| `WALLIX_USERNAME` | WALLIX username | `admin` |
| `WALLIX_PASSWORD` | WALLIX password | *(required)* |
| `OPENSHIFT_NAMESPACE` | Target OpenShift namespace | `default` |
| `SECRET_NAME_PREFIX` | Prefix for secret names | `wallix` |
| `VERBOSE` | Verbose mode | `false` |
| `DRY_RUN` | Dry-run mode | `false` |

## Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-v, --verbose` | Verbose mode |
| `-d, --dry-run` | Dry-run mode |
| `-n, --namespace NS` | OpenShift namespace |
| `-p, --prefix PREFIX` | Secret name prefix |

## Format of Created Secrets

The created OpenShift secrets will have:

- **Name**: `{prefix}-{account}-{target}-{domain}` (lowercase, special characters replaced by `-`)
- **Type**: `generic`
- **Key**: `password`
- **Value**: The password retrieved from WALLIX

### Example

```bash
# Command
./pull_secret_to_vault.sh -p myapp admin@Web-Server@Corp

# Created secret
Name: myapp-admin-web-server-corp
Type: Opaque
Data:
  password: <retrieved_password>
```

## Using Secrets in OpenShift

### 1. In a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
   image: my-app:latest
   env:
   - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
       name: wallix-postgres-dbserver-local
       key: password
```

### 2. As a Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
   image: my-app:latest
   volumeMounts:
   - name: db-password
    mountPath: "/etc/secrets"
    readOnly: true
  volumes:
  - name: db-password
   secret:
    secretName: wallix-postgres-dbserver-local
```

### 3. In a Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
   spec:
    containers:
    - name: app
      image: my-app:latest
      envFrom:
      - secretRef:
        name: wallix-admin-webserver-corp
```

## Security

### Best Practices

1. **Environment Variables**: Use environment variables for passwords
2. **Permissions**: Limit script permissions (`chmod 750`)
3. **Cleanup**: The script automatically cleans up temporary files
4. **RBAC**: Configure appropriate OpenShift permissions

### OpenShift RBAC Example

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-manager
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "delete", "get", "list"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["create", "get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-manager-binding
subjects:
- kind: User
  name: your-username
roleRef:
  kind: Role
  name: secret-manager
  apiGroup: rbac.authorization.k8s.io
```

## Troubleshooting

### Common Errors

#### 1. WALLIX Authentication Error

```
ERROR: Authentication failed with status 401
```

**Solution**: Check `WALLIX_USERNAME` and `WALLIX_PASSWORD`

#### 2. Endpoint Not Found

```
ERROR: Failed to retrieve password. Status: 404
```

**Solution**: The script tests several endpoint patterns. Check that the target and account exist in WALLIX.

#### 3. Not Connected to OpenShift

```
ERROR: Not logged into OpenShift
```

**Solution**: Run `oc login` before using the script

#### 4. Insufficient Permissions

```
ERROR: forbidden: User cannot create secrets
```

**Solution**: Configure appropriate RBAC permissions

### Debug Mode

```bash
# Enable verbose mode for more details
VERBOSE=true ./pull_secret_to_vault.sh -v target account

# Dry-run mode for testing
DRY_RUN=true ./pull_secret_to_vault.sh -d target account
```

## CI/CD Integration

### Example with GitLab CI

```yaml
sync-secrets:
  stage: deploy
  image: registry.redhat.io/ubi8/ubi:latest
  before_script:
   - curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
   - tar -xzf openshift-client-linux.tar.gz && mv oc /usr/local/bin/
   - oc login $OPENSHIFT_URL --token=$OPENSHIFT_TOKEN
  script:
   - ./pull_secret_to_vault.sh -n production postgres@database@prod
  only:
   - main
```

### Example with GitHub Actions

```yaml
name: Sync WALLIX Secrets
on:
  push:
   branches: [main]
jobs:
  sync-secrets:
   runs-on: ubuntu-latest
   steps:
   - uses: actions/checkout@v3
   - name: Install OpenShift CLI
    run: |
      curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
      tar -xzf openshift-client-linux.tar.gz
      sudo mv oc /usr/local/bin/
   - name: Login to OpenShift
    run: oc login ${{ secrets.OPENSHIFT_URL }} --token=${{ secrets.OPENSHIFT_TOKEN }}
   - name: Sync Secrets
    env:
      WALLIX_PASSWORD: ${{ secrets.WALLIX_PASSWORD }}
    run: ./pull_secret_to_vault.sh -n production admin@webserver@corp
```

## Support

For questions or issues:

1. Check the **Troubleshooting** section
2. Use verbose mode (`-v`) for more details
3. Test with dry-run mode (`-d`) first

---

> **Note**: This simple bash script is not suitable for production but helps quickly test importing secrets from WALLIX Bastion Vault via the API.
