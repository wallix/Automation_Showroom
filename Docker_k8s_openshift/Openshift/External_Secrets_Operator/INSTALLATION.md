# External Secrets Operator - Installation Guide

> **⚠️ Important:** ESO v0.20+ uses API version `v1` (not `v1beta1`) and requires proper certificate validation.

## 🚀 Quick Start (30 Minutes)

Follow these steps for a complete ESO + WALLIX integration:

1. **[Install ESO](#step-2-install-external-secrets-operator)** - Deploy via Helm (5 min)
2. **[Create WALLIX Credentials](#step-3-create-wallix-api-credentials-secret)** - Configure API access (5 min)
3. **[Extract Certificate](#certificate-configuration)** - For TLS validation (5 min)
4. **[Deploy SecretStore](#step-4-deploy-wallix-secretstore)** - Connect to WALLIX (5 min)
5. **[Create ExternalSecret](#step-5-create-your-first-externalsecret)** - Sync passwords (5 min)
6. **[Test & Verify](#🧪-testing)** - Validate the setup (5 min)

---

## 📋 Prerequisites

Before installing External Secrets Operator (ESO) with WALLIX Bastion integration, ensure you have:

- ✅ **Helm 3.0+** installed
- ✅ **kubectl** configured and connected to your cluster
- ✅ Kubernetes **1.19+** or OpenShift **4.8+**
- ✅ Network access to WALLIX Bastion
- ✅ WALLIX API credentials with checkout permissions

## 🚀 Step-by-Step Installation

### Step 1: Install Helm (if not already installed)

```bash
# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# macOS
brew install helm

# Verify installation
helm version
```

### Step 2: Install External Secrets Operator

```bash
# Add the External Secrets Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Create namespace
kubectl create namespace external-secrets-system

# Install External Secrets Operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --set installCRDs=true \
  --set webhook.port=9443

# Verify installation
kubectl get pods -n external-secrets-system
kubectl get crd | grep external-secrets
```

**Expected output:**

```ini
NAME                                   READY   STATUS    RESTARTS   AGE
external-secrets-768b5d8d5f-xxxxx     1/1     Running   0          1m
external-secrets-webhook-xxxxx-xxxxx   1/1     Running   0          1m
```

### Step 3: Create WALLIX API Credentials Secret

```bash
# Replace with your actual WALLIX credentials
kubectl create secret generic wallix-api-credentials \
  --from-literal=api-user='admin' \
  --from-literal=api-key='YOUR_WALLIX_API_KEY_HERE' \
  -n default

# Verify secret creation
kubectl get secret wallix-api-credentials -n default
```

### Certificate Configuration

**⚠️ ESO v0.20+ requires proper TLS validation** - no `insecureSkipVerify` option available.

#### Option 1: Use DNS Hostname (Recommended)

```bash
# Use WALLIX DNS name instead of IP address
export WALLIX_URL="https://wallix-bastion.example.com"
```

#### Option 2: Extract and Use CA Certificate

```bash
# Extract WALLIX CA certificate
echo | openssl s_client -connect ${WALLIX_URL#https://}:443 -showcerts 2>/dev/null | \
  openssl x509 -outform PEM > /tmp/wallix-ca.pem

# Create ConfigMap with CA certificate
kubectl create configmap wallix-ca \
  --from-file=ca.crt=/tmp/wallix-ca.pem \
  -n default

# Verify ConfigMap
kubectl get configmap wallix-ca -n default
```

**Note:** If using self-signed certificate with IP address, ensure the certificate includes IP SAN (Subject Alternative Name).

### Step 4: Deploy WALLIX SecretStore

**⚠️ API Version Change:** ESO v0.20+ uses `external-secrets.io/v1` (not `v1beta1`)

```bash
# Deploy SecretStore with v1 API and certificate validation
cat > wallix-secretstore.yaml <<EOF
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: wallix-bastion
  namespace: default
spec:
  provider:
    webhook:
      url: "https://YOUR-WALLIX-URL/api/targetpasswords/checkout/{{ .remoteRef.key }}"
      method: GET
      headers:
        Content-Type: "application/json"
        X-Auth-User: "{{ .authUser }}"
        X-Auth-Key: "{{ .authKey }}"
      secrets:
      - name: authUser
        secretRef:
          name: wallix-api-credentials
          key: api-user
      - name: authKey
        secretRef:
          name: wallix-api-credentials
          key: api-key
      result:
        jsonPath: "$.password"
      caProvider:
        type: ConfigMap
        name: wallix-ca
        key: ca.crt
        namespace: default
EOF

# Apply the SecretStore
kubectl apply -f wallix-secretstore.yaml

# Verify SecretStore is ready
kubectl get secretstore wallix-bastion
```

**Expected status:**

```ini
NAME             AGE   STATUS   READY
wallix-bastion   10s   Valid    True
```

### Step 5: Create Your First ExternalSecret

```bash
# Create an ExternalSecret to fetch a password from WALLIX
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: wallix-bastion
    kind: SecretStore
  target:
    name: db-password-secret
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: admin@prodl@db-postgres  # WALLIX key format: account@domain@target
EOF

# Verify ExternalSecret status
kubectl get externalsecret database-credentials
kubectl get secret db-password-secret
```

**Expected output:**

```ini
NAME                    STORE            REFRESH INTERVAL   STATUS
database-credentials    wallix-bastion   1h                 SecretSynced

NAME                 TYPE     DATA   AGE
db-password-secret   Opaque   1      10s
```

## 🔧 Configuration Options

### Certificate Validation

**ESO v0.20+ requires proper certificate validation:**

#### Using CA Certificate (Recommended)

```yaml
spec:
  provider:
    webhook:
      # ... other config ...
      caProvider:
        type: ConfigMap
        name: wallix-ca
        key: ca.crt
        namespace: default
```

#### Using DNS Hostname

```yaml
spec:
  provider:
    webhook:
      url: "https://wallix-bastion.example.com/api/targetpasswords/checkout/{{ .remoteRef.key }}"
      # ... rest of config ...
```

**⚠️ Note:** `insecureSkipVerify` is **not available** in ESO v0.20+. Use proper certificates or DNS names.

### Multiple WALLIX Secrets

Create an ExternalSecret with multiple keys:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: multi-credentials
  namespace: default
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: wallix-bastion
    kind: SecretStore
  target:
    name: application-secrets
    creationPolicy: Owner
  data:
  - secretKey: db-password
    remoteRef:
      key: admin@db-postgres@prod.local
  - secretKey: api-key
    remoteRef:
      key: apiuser@external-api@prod.local
  - secretKey: ssh-key
    remoteRef:
      key: deploy@gitserver@prod.local
```

### ClusterSecretStore (Cluster-wide)

For use across multiple namespaces:

```bash
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: wallix-bastion-global
spec:
  provider:
    webhook:
      url: "https://YOUR-WALLIX-URL/api/targetpasswords/checkout/{{ .remoteRef.key }}"
      method: GET
      headers:
        Content-Type: "application/json"
        X-Auth-User: "{{ .authUser }}"
        X-Auth-Key: "{{ .authKey }}"
      secrets:
      - name: authUser
        secretRef:
          name: wallix-api-credentials
          namespace: external-secrets-system  # Note: namespace required for ClusterSecretStore
          key: api-user
      - name: authKey
        secretRef:
          name: wallix-api-credentials
          namespace: external-secrets-system
          key: api-key
      result:
        jsonPath: "$.password"
      caProvider:
        type: ConfigMap
        name: wallix-ca
        key: ca.crt
        namespace: external-secrets-system
EOF
```

## 🧪 Testing

### Test WALLIX Connection

```bash
# Use the provided test script
./scripts/test-connection.sh
```

### Manual Test

```bash
# Get the synced secret
kubectl get secret db-password-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

### Validate All Secrets

```bash
# Use the validation script
./scripts/validate-secrets.sh
```

## 📊 Monitoring

### Monitor ESO Resources

```bash
# Use the monitoring script
./scripts/monitor.sh

# Or manually:
kubectl get externalsecrets -A
kubectl get secretstores -A
kubectl describe externalsecret <name>
```

### Check ESO Logs

```bash
# Controller logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets -f

# Webhook logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets-webhook -f
```

## 🔄 Upgrading ESO

```bash
# Update Helm repository
helm repo update

# Check available versions
helm search repo external-secrets/external-secrets --versions

# Upgrade to latest version
helm upgrade external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --reuse-values

# Or upgrade to specific version
helm upgrade external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --version 0.10.4 \
  --reuse-values
```

## 🧹 Cleanup

### Remove Everything

```bash
# Use the cleanup script
./scripts/cleanup.sh

# Or manually:
# Delete ExternalSecrets
kubectl delete externalsecret --all -A

# Delete SecretStores
kubectl delete secretstore --all -A
kubectl delete clustersecretstore --all

# Uninstall ESO
helm uninstall external-secrets -n external-secrets-system
kubectl delete namespace external-secrets-system

# Delete CRDs (optional, removes all ESO resources)
kubectl delete crd externalsecrets.external-secrets.io
kubectl delete crd secretstores.external-secrets.io
kubectl delete crd clustersecretstores.external-secrets.io
```

## 🚨 Troubleshooting

### ESO Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Check for resource issues
kubectl top pod -n external-secrets-system

# Check webhook certificate
kubectl get secret -n external-secrets-system
```

### SecretStore Not Ready

```bash
# Check SecretStore status
kubectl get secretstore wallix-bastion -o yaml

# Test WALLIX connectivity
curl -k -H "X-Auth-User: admin" -H "X-Auth-Key: YOUR_KEY" \
  "https://YOUR-BASTION-URL/api/targetpasswords/checkout/test@test@test"

# Verify credentials secret
kubectl get secret wallix-api-credentials -o yaml
```

### ExternalSecret Not Syncing

```bash
# Check ExternalSecret events
kubectl describe externalsecret <name>

# Check ESO controller logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets --tail=100

# Force refresh
kubectl annotate externalsecret <name> force-sync="$(date +%s)" --overwrite
```

### Certificate Issues

```bash
# For self-signed certificates, extract the CA:
openssl s_client -connect YOUR-BASTION:443 -showcerts </dev/null 2>/dev/null | \
  openssl x509 -outform PEM > wallix-ca.pem

# Add to SecretStore:
kubectl create configmap wallix-ca --from-file=ca.crt=wallix-ca.pem
# Then reference in SecretStore caBundle
```

## 📚 Next Steps

1. ✅ Review [examples/](./examples/) for complete configurations
2. ✅ Use [scripts/](./scripts/) for automation
3. ✅ Read [ESO Documentation](https://external-secrets.io/)
4. ✅ Set up monitoring and alerts
5. ✅ Plan backup and disaster recovery

## 🔗 Additional Resources

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [Webhook Provider Guide](https://external-secrets.io/latest/provider/webhook/)
- [WALLIX Bastion API Documentation](https://documentation.wallix.com)
- [Helm Charts](https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets)
