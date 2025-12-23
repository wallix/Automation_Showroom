# WALLIX Simple OpenShift Integration - Lab Deployment Guide

## 🎯 Quick Deployment

This guide will help you deploy the WALLIX Simple Integration on your OpenShift/Kubernetes lab.

## 📋 Prerequisites

1. **OpenShift/Kubernetes cluster access**
   - `oc` CLI tool installed (for OpenShift)
   - OR `kubectl` CLI tool installed (for Kubernetes)
   - Logged in to your cluster

2. **WALLIX Bastion**
   - WALLIX Bastion accessible from your cluster
   - API user with checkout permissions
   - API key generated

3. **Network connectivity**
   - Cluster can reach WALLIX Bastion (typically HTTPS/443)

## 🚀 Quick Start (Automated)

### Step 1: Navigate to the directory

```bash
cd Docker_k8s_openshift/Openshift/WALLIX_Simple_Integration/scripts
```

### Step 2: Create configuration file

```bash
# Copy the example config
cp wallix-config.env.example wallix-config.env

# Edit with your WALLIX Bastion details
nano wallix-config.env  # or vim, vi, code, etc.
```

**Required configuration:**
```bash
# Your WALLIX Bastion URL
BASTION_URL="https://your-bastion.example.com"

# API credentials
API_USER="admin"
API_KEY="your-actual-api-key-here"

# Secret to retrieve (format: account@target@domain)
SECRET_KEY="admin@myserver@production.local"
```

### Step 3: Run the deployment script

```bash
./deploy-lab.sh
```

The script will:
1. ✅ Check cluster connectivity
2. ✅ Validate WALLIX Bastion access
3. ✅ Test API credentials
4. ✅ Let you choose deployment type
5. ✅ Deploy to your cluster

### Step 4: Choose deployment type

The script will ask you to select:

**Option 1: Init Container (Recommended)**
- Fetches secrets at pod startup
- Stores in memory (secure)
- Best for most use cases

**Option 2: CronJob Sync**
- Periodic secret synchronization
- Good for automatic secret rotation
- Creates Kubernetes secrets

**Option 3: Test Connection**
- Just tests WALLIX connectivity
- No application deployed

## 📝 Manual Deployment

If you prefer manual deployment:

### 1. Create namespace

```bash
kubectl create namespace wallix-demo
# or for OpenShift:
oc new-project wallix-demo
```

### 2. Create API credentials secret

```bash
kubectl create secret generic wallix-api-credentials \
  --from-literal=api-user='admin' \
  --from-literal=api-key='YOUR_API_KEY' \
  -n wallix-demo
```

### 3. Deploy init container example

```bash
# Edit the example file first
nano ../examples/init-container-wallix.yaml

# Update these values:
# - your-bastion.example.com → Your Bastion URL
# - admin@db-postgres@prod.local → Your secret key

# Apply
kubectl apply -f ../examples/init-container-wallix.yaml -n wallix-demo
```

### 4. Verify deployment

```bash
# Check pods
kubectl get pods -n wallix-demo

# View init container logs
kubectl logs -n wallix-demo <pod-name> -c fetch-wallix-password

# View application logs
kubectl logs -n wallix-demo <pod-name> -c app
```

## 🔍 Verification

### Check pod status

```bash
kubectl get pods -n wallix-demo
```

Expected output:
```
NAME                                      READY   STATUS    RESTARTS   AGE
app-with-wallix-secrets-xxxxxxxxxx-xxxxx  1/1     Running   0          30s
```

### View init container logs

```bash
POD_NAME=$(kubectl get pods -n wallix-demo -l app=myapp -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n wallix-demo $POD_NAME -c fetch-wallix-password
```

Expected output:
```
Fetching password from WALLIX Bastion...
Password successfully fetched and stored
```

### Test secret retrieval

```bash
# Exec into the pod and check the secret file
kubectl exec -it -n wallix-demo $POD_NAME -- cat /secrets/database-password
```

## 🛠️ Troubleshooting

### Issue: Cannot reach WALLIX Bastion

```bash
# Test connectivity from a pod
kubectl run -it --rm test --image=curlimages/curl -n wallix-demo -- \
  curl -k https://your-bastion.example.com
```

**Solutions:**
- Verify Bastion URL
- Check network policies
- Verify firewall rules
- Check DNS resolution

### Issue: API authentication failed (401)

**Symptoms:**
```
ERROR: Failed to fetch password
HTTP 401 Unauthorized
```

**Solutions:**
- Verify API_USER in secret
- Verify API_KEY in secret
- Check user has checkout permissions in WALLIX
- Regenerate API key if needed

### Issue: Secret not found (404)

**Symptoms:**
```
ERROR: Failed to fetch password
HTTP 404 Not Found
```

**Solutions:**
- Verify secret key format: `account@target@domain`
- Check the account exists in WALLIX
- Check the target exists in WALLIX
- Check the domain exists in WALLIX
- Verify user has access to this account

### Issue: Init container fails

```bash
# View detailed init container logs
kubectl describe pod -n wallix-demo $POD_NAME

# Check events
kubectl get events -n wallix-demo --sort-by='.lastTimestamp'
```

### Issue: Secret file is empty

```bash
# Check if jq is available in the init container
kubectl exec -it -n wallix-demo $POD_NAME -c fetch-wallix-password -- jq --version
```

If jq is missing, the curl command won't parse JSON correctly.

## 📊 Available Examples

### Init Container Examples

Located in `examples/init-container-wallix.yaml`:

1. **Simple single secret**
   - One init container
   - One database password
   - Basic setup

2. **Multiple secrets**
   - Multiple init containers
   - Database password + API key
   - Advanced setup

### CronJob Example

Located in `examples/cronjob-wallix-sync.yaml`:

- Runs every 15 minutes (customizable)
- Syncs multiple secrets
- Creates Kubernetes secrets
- Applications use standard secret mounts

### Test Connection Example

Located in `examples/test-wallix-connection.yaml`:

- Simple test pod
- Validates API connectivity
- Shows secret retrieval
- No persistent deployment

## 🔒 Security Best Practices

1. **Use Network Policies**
   ```bash
   # Limit which pods can access WALLIX Bastion
   kubectl apply -f network-policy.yaml
   ```

2. **Use RBAC**
   ```bash
   # Limit access to wallix-api-credentials secret
   kubectl create role secret-reader --verb=get --resource=secrets
   ```

3. **Use Memory volumes**
   - Init container examples use `emptyDir` with `medium: Memory`
   - Secrets never touch disk

4. **Rotate API keys regularly**
   - Update secret: `kubectl create secret generic wallix-api-credentials ... --dry-run=client -o yaml | kubectl apply -f -`

5. **Use valid TLS certificates**
   - Replace `-k` flag in curl commands
   - Add WALLIX CA to container image

## 📚 Additional Resources

- [WALLIX API Documentation](https://docs.wallix.com/api)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

## 🆘 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review WALLIX Bastion logs
3. Check Kubernetes/OpenShift events and logs
4. Contact WALLIX support

## 📝 Next Steps

After successful deployment:

1. **Customize for your application**
   - Edit deployment YAML
   - Add your application container
   - Configure environment variables

2. **Add more secrets**
   - Add more init containers
   - Retrieve multiple passwords
   - Store in separate files

3. **Implement secret rotation**
   - Use CronJob pattern
   - Configure rotation schedule
   - Update application to reload secrets

4. **Production hardening**
   - Use valid TLS certificates
   - Configure network policies
   - Set resource limits
   - Add monitoring and alerting
