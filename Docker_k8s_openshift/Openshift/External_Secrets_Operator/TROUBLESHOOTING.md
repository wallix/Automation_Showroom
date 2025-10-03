# 🔧 Troubleshooting Guide - External Secrets Operator with WALLIX

This guide covers common issues when using External Secrets Operator with WALLIX Bastion.

## 📋 Table of Contents

1. [Installation Issues](#installation-issues)
2. [SecretStore Issues](#secretstore-issues)
3. [ExternalSecret Issues](#externalsecret-issues)
4. [WALLIX API Issues](#wallix-api-issues)
5. [Certificate Issues](#certificate-issues)
6. [Performance Issues](#performance-issues)
7. [Debugging Tools](#debugging-tools)

---

## Installation Issues

### ESO Pods Not Starting

**Symptoms:**

```bash
$ kubectl get pods -n external-secrets-system
NAME                                    READY   STATUS             RESTARTS   AGE
external-secrets-768b5d8d5f-xxxxx      0/1     CrashLoopBackOff   5          3m
```

**Diagnosis:**

```bash
# Check pod events
kubectl describe pod -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Check logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets --tail=100

# Check resource constraints
kubectl top pod -n external-secrets-system
kubectl describe node | grep -A 5 "Allocated resources"
```

**Common Causes & Solutions:**

1. **Insufficient Resources**

   ```bash
   # Increase resource limits
   helm upgrade external-secrets external-secrets/external-secrets \
     -n external-secrets-system \
     --set resources.requests.cpu=100m \
     --set resources.requests.memory=128Mi \
     --set resources.limits.cpu=500m \
     --set resources.limits.memory=256Mi \
     --reuse-values
   ```

2. **Webhook Port Conflict**

   ```bash
   # Check if port 9443 is already in use
   kubectl get svc -A | grep 9443
   
   # Change webhook port
   helm upgrade external-secrets external-secrets/external-secrets \
     -n external-secrets-system \
     --set webhook.port=9444 \
     --reuse-values
   ```

3. **RBAC Issues**

   ```bash
   # Verify RBAC
   kubectl get clusterrole | grep external-secrets
   kubectl get clusterrolebinding | grep external-secrets
   
   # Reinstall with proper RBAC
   helm upgrade external-secrets external-secrets/external-secrets \
     -n external-secrets-system \
     --set installCRDs=true \
     --reuse-values
   ```

### CRDs Not Installing

**Symptoms:**

```bash
$ kubectl get crd | grep external-secrets
# No results
```

**Solution:**

```bash
# Install CRDs manually
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml

# Or use Helm with CRDs
helm upgrade external-secrets external-secrets/external-secrets \
  -n external-secrets-system \
  --set installCRDs=true \
  --reuse-values
```

---

## SecretStore Issues

### SecretStore Not Ready

**Symptoms:**

```bash
$ kubectl get secretstore wallix-bastion
NAME             AGE   STATUS    READY
wallix-bastion   2m    Invalid   False
```

**Diagnosis:**

```bash
# Check SecretStore details
kubectl describe secretstore wallix-bastion

# Check events
kubectl get events --field-selector involvedObject.name=wallix-bastion

# Validate referenced secret
kubectl get secret wallix-api-credentials -o yaml
```

**Common Causes & Solutions:**

1. **Missing Credentials Secret**

   ```bash
   # Verify secret exists
   kubectl get secret wallix-api-credentials
   
   # Recreate if missing
   kubectl create secret generic wallix-api-credentials \
     --from-literal=api-user='admin' \
     --from-literal=api-key='your-api-key' \
     -n default
   ```

2. **Wrong Secret Keys**

   ```bash
   # Check secret keys
   kubectl get secret wallix-api-credentials -o jsonpath='{.data}' | jq
   
   # Should have: api-user and api-key
   # Fix SecretStore to match actual keys
   ```

3. **Invalid WALLIX URL**

   ```bash
   # Test URL manually
   WALLIX_URL="https://your-bastion.example.com"
   WALLIX_USER="admin"
   WALLIX_KEY="your-api-key"
   
   curl -k -H "X-Auth-User: ${WALLIX_USER}" \
        -H "X-Auth-Key: ${WALLIX_KEY}" \
        "${WALLIX_URL}/api/targetpasswords/checkout/test@test@test"
   
   # Should return 200 or 404 (not connection error)
   ```

### ClusterSecretStore Namespace Issues

**Symptoms:**

```bash
Error: secret "wallix-api-credentials" not found in namespace "external-secrets-system"
```

**Solution:**

```bash
# ClusterSecretStore requires credentials in the SAME namespace as ESO
kubectl create secret generic wallix-api-credentials \
  --from-literal=api-user='admin' \
  --from-literal=api-key='your-api-key' \
  -n external-secrets-system

# Update ClusterSecretStore with v1 API
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
          namespace: external-secrets-system
          key: api-user
      - name: authKey
        secretRef:
          name: wallix-api-credentials
          namespace: external-secrets-system
          key: api-key
      result:
        jsonPath: "$.password"
EOF
```

---

## ExternalSecret Issues

### ExternalSecret Not Syncing

**Symptoms:**

```bash
$ kubectl get externalsecret my-secret
NAME        STORE            REFRESH INTERVAL   STATUS          READY
my-secret   wallix-bastion   1h                 SecretSyncErr   False
```

**Diagnosis:**

```bash
# Check ExternalSecret status
kubectl describe externalsecret my-secret

# Check controller logs
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets \
  --tail=100 | grep my-secret

# Force refresh
kubectl annotate externalsecret my-secret \
  force-sync="$(date +%s)" --overwrite
```

**Common Causes & Solutions:**

1. **Invalid WALLIX Key Format**

   ```bash
   # Correct format: account@target@domain
   # Examples:
   #   admin@database-server@prod.local
   #   deploy@web-server-01@dmz.local
   #   apiuser@external-api@cloud.local
   
   # Test key manually
   WALLIX_KEY="admin@database-server@prod.local"
   curl -k -H "X-Auth-User: admin" -H "X-Auth-Key: your-key" \
     "https://bastion.example.com/api/targetpasswords/checkout/${WALLIX_KEY}"
   ```

2. **Wrong JSONPath**

   ```yaml
   # WALLIX API returns: {"password": "secret123"}
   # Correct JSONPath:
   spec:
     provider:
       webhook:
         result:
           jsonPath: "$.password"  # Correct
           # jsonPath: ".password" # Wrong
           # jsonPath: "password"  # Wrong
   ```

3. **Target Secret Already Exists**

   ```bash
   # If secret exists and owned by something else
   kubectl get secret my-secret -o yaml | grep ownerReferences
   
   # Delete and let ESO recreate
   kubectl delete secret my-secret
   
   # Or change creationPolicy
   kubectl patch externalsecret my-secret --type=merge -p '
   spec:
     target:
       creationPolicy: Merge  # Or None
   '
   ```

### Secret Not Refreshing

**Symptoms:**

- Secret contains old password
- RefreshInterval passed but no update

**Diagnosis:**

```bash
# Check last refresh time
kubectl get externalsecret my-secret -o yaml | grep -A 5 status

# Check refresh interval
kubectl get externalsecret my-secret -o yaml | grep refreshInterval
```

**Solutions:**

1. **Force Immediate Refresh**

   ```bash
   kubectl annotate externalsecret my-secret \
     force-sync="$(date +%s)" --overwrite
   ```

2. **Adjust Refresh Interval**

   ```bash
   kubectl patch externalsecret my-secret --type=merge -p '
   spec:
     refreshInterval: 5m  # More frequent
   '
   ```

3. **Check ESO Controller Health**

   ```bash
   # Restart controller if stuck
   kubectl rollout restart deployment external-secrets \
     -n external-secrets-system
   ```

---

## WALLIX API Issues

### Authentication Failures

**Symptoms:**

```
Error: 401 Unauthorized
Error: 403 Forbidden
```

**Diagnosis:**

```bash
# Test credentials manually
curl -k -v \
  -H "X-Auth-User: admin" \
  -H "X-Auth-Key: your-api-key" \
  "https://bastion.example.com/api/targetpasswords/checkout/test@test@test"

# Check response headers and status code
```

**Common Causes & Solutions:**

1. **Missing X-Auth-User Header**

   ```yaml
   # WALLIX requires BOTH headers
   spec:
     provider:
       webhook:
         headers:
           X-Auth-User:  # Required
             - valueFrom:
                 secretKeyRef:
                   name: wallix-api-credentials
                   key: api-user
           X-Auth-Key:   # Required
             - valueFrom:
                 secretKeyRef:
                   name: wallix-api-credentials
                   key: api-key
   ```

2. **Expired or Invalid API Key**

   ```bash
   # Generate new API key in WALLIX admin interface
   # Update secret
   kubectl create secret generic wallix-api-credentials \
     --from-literal=api-user='admin' \
     --from-literal=api-key='new-api-key' \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

3. **Insufficient Permissions**

   ```bash
   # Verify user has "checkout" permission in WALLIX
   # Check WALLIX audit logs for permission denials
   ```

### Target Not Found (404)

**Symptoms:**

```
Error: 404 Not Found
Error: Target password not found
```

**Solutions:**

1. **Verify Target Exists in WALLIX**

   ```bash
   # List available targets (if API supports)
   curl -k -H "X-Auth-User: admin" -H "X-Auth-Key: your-key" \
     "https://bastion.example.com/api/targets"
   
   # Verify account exists on target
   curl -k -H "X-Auth-User: admin" -H "X-Auth-Key: your-key" \
     "https://bastion.example.com/api/accounts"
   ```

2. **Check Key Format**

   ```bash
   # Format: account@target@domain
   # Must match EXACTLY as configured in WALLIX
   
   # Wrong: admin@database_server@prod.local (underscore)
   # Right: admin@database-server@prod.local (hyphen)
   ```

### HTTP 302 Redirects

**Symptoms:**

```
Error: HTTP 302 Found
Unexpected redirect response
```

**Cause:** Accessing base URL instead of API endpoint

**Solution:**

```yaml
# Ensure URL includes API path and template
spec:
  provider:
    webhook:
      # Wrong:
      # url: "https://bastion.example.com/{{ .remoteRef.key }}"
      
      # Correct:
      url: "https://bastion.example.com/api/targetpasswords/checkout/{{ .remoteRef.key }}"
```

---

## Certificate Issues

### TLS Validation Errors

**Symptoms:**

```
Error: x509: certificate signed by unknown authority
Error: x509: cannot validate certificate for <IP> because it doesn't contain any IP SANs
Error: certificate verify failed
```

**⚠️ Important:** ESO v0.20+ **does not support** `insecureSkipVerify`. You must use proper certificate validation.

**Solutions:**

**Solution 1: Use DNS Hostname (Recommended)**

```bash
# Use WALLIX DNS name instead of IP address
export WALLIX_URL="https://wallix-bastion.example.com"

# Update SecretStore
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: wallix-bastion
  namespace: default
spec:
  provider:
    webhook:
      url: "https://wallix-bastion.example.com/api/targetpasswords/checkout/{{ .remoteRef.key }}"
      # ... rest of config ...
EOF
```

**Solution 2: Extract and Use CA Certificate**

```bash
# Extract CA certificate from WALLIX
echo | openssl s_client -connect your-wallix:443 -showcerts 2>/dev/null | \
  openssl x509 -outform PEM > /tmp/wallix-ca.pem

# Create ConfigMap
kubectl create configmap wallix-ca \
  --from-file=ca.crt=/tmp/wallix-ca.pem \
  -n default

# Update SecretStore with caProvider
kubectl apply -f - <<EOF
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
```

**Solution 3: Fix Certificate IP SAN**

If you must use an IP address, ensure the WALLIX certificate includes IP SAN:

```bash
# Check certificate SANs
echo | openssl s_client -connect 192.168.1.75:443 2>/dev/null | \
  openssl x509 -noout -text | grep -A1 "Subject Alternative Name"

# If IP SAN is missing, regenerate WALLIX certificate with IP SAN
# (This must be done on WALLIX Bastion itself)
```

**⚠️ Note:** ESO v0.20+ removed `insecureSkipVerify`. Downgrade to v0.9.x if you need this option (not recommended).

---

## Performance Issues

### Slow Secret Sync

**Symptoms:**

- Secrets take minutes to sync
- High CPU usage on ESO controller

**Diagnosis:**

```bash
# Check controller resource usage
kubectl top pod -n external-secrets-system

# Check number of ExternalSecrets
kubectl get externalsecret -A | wc -l

# Check refresh intervals
kubectl get externalsecret -A -o yaml | grep refreshInterval | sort | uniq -c
```

**Solutions:**

1. **Optimize Refresh Intervals**

   ```bash
   # Don't refresh too frequently
   # Minimum recommended: 5m for frequent, 1h for normal
   kubectl patch externalsecret my-secret --type=merge -p '
   spec:
     refreshInterval: 1h  # Instead of 1m
   '
   ```

2. **Increase Controller Resources**

   ```bash
   helm upgrade external-secrets external-secrets/external-secrets \
     -n external-secrets-system \
     --set resources.limits.cpu=1000m \
     --set resources.limits.memory=512Mi \
     --reuse-values
   ```

3. **Use ClusterSecretStore**

   ```bash
   # Share SecretStore across namespaces instead of creating many
   kubectl apply -f examples/cluster-secretstore.yaml
   ```

### WALLIX API Rate Limiting

**Symptoms:**

```
Error: 429 Too Many Requests
Error: Rate limit exceeded
```

**Solutions:**

1. **Increase Refresh Intervals**

   ```bash
   # Reduce API call frequency
   kubectl get externalsecret -A -o json | \
     jq -r '.items[] | select(.spec.refreshInterval=="1m") | .metadata.name' | \
     xargs -I {} kubectl patch externalsecret {} --type=merge -p '{"spec":{"refreshInterval":"15m"}}'
   ```

2. **Implement Backoff**

   ```yaml
   # Add to SecretStore
   spec:
     provider:
       webhook:
         timeout: 30s
         # ESO handles retries automatically with exponential backoff
   ```

---

## Debugging Tools

### Quick Health Check

```bash
# Use the monitoring script
./scripts/monitor.sh

# Or manually:
echo "=== ESO Pods ==="
kubectl get pods -n external-secrets-system

echo -e "\n=== SecretStores ==="
kubectl get secretstore -A

echo -e "\n=== ExternalSecrets ==="
kubectl get externalsecret -A

echo -e "\n=== Recent Events ==="
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```

### Test WALLIX Connection

```bash
# Use the test script
./scripts/test-connection.sh

# Or manually:
WALLIX_URL="https://bastion.example.com"
WALLIX_USER="admin"
WALLIX_KEY="your-api-key"
WALLIX_TARGET="admin@test@test"

curl -k -v \
  -H "X-Auth-User: ${WALLIX_USER}" \
  -H "X-Auth-Key: ${WALLIX_KEY}" \
  "${WALLIX_URL}/api/targetpasswords/checkout/${WALLIX_TARGET}" 2>&1 | \
  grep -E "< HTTP|< X-|password"
```

### Validate All Secrets

```bash
# Use the validation script
./scripts/validate-secrets.sh

# Check specific secret
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

### Enable Debug Logging

```bash
# Increase ESO log verbosity
helm upgrade external-secrets external-secrets/external-secrets \
  -n external-secrets-system \
  --set extraArgs={--enable-debug-log=true} \
  --reuse-values

# Watch logs
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets \
  -f --tail=100
```

### Collect Diagnostic Info

```bash
# Use this for support requests
cat > eso-diagnostics.sh <<'EOF'
#!/bin/bash
echo "=== ESO Version ==="
helm list -n external-secrets-system

echo -e "\n=== ESO Pods ==="
kubectl get pods -n external-secrets-system -o wide

echo -e "\n=== CRDs ==="
kubectl get crd | grep external-secrets

echo -e "\n=== SecretStores ==="
kubectl get secretstore,clustersecretstore -A

echo -e "\n=== ExternalSecrets ==="
kubectl get externalsecret -A -o wide

echo -e "\n=== Recent Events ==="
kubectl get events -n external-secrets-system --sort-by='.lastTimestamp' | tail -30

echo -e "\n=== Controller Logs ==="
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets --tail=50
EOF

chmod +x eso-diagnostics.sh
./eso-diagnostics.sh > diagnostics.txt
```

---

## 🆘 Getting More Help

1. **Check Documentation**
   - [External Secrets Operator Docs](https://external-secrets.io/)
   - [WALLIX API Documentation](https://documentation.wallix.com)
   - [Webhook Provider Guide](https://external-secrets.io/latest/provider/webhook/)

2. **Community Support**
   - [ESO GitHub Issues](https://github.com/external-secrets/external-secrets/issues)
   - [ESO Slack Channel](https://kubernetes.slack.com/archives/external-secrets)

3. **Collect Diagnostics**

   ```bash
   ./eso-diagnostics.sh > diagnostics.txt
   # Attach to support request
   ```

4. **Check Scripts**
   - [scripts/README.md](./scripts/README.md) for automation tools
   - [scripts/monitor.sh](./scripts/monitor.sh) for real-time monitoring
   - [scripts/validate-secrets.sh](./scripts/validate-secrets.sh) for validation
