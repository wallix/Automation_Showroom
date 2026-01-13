# Deploy WALLIX Access Manager and Bastion

terraform init
terraform apply -var-file=<VAR_FILE>

example terraform apply -var-file=access-manager-4.3.0.3.tfvars

## GCP

GCP needs a [service account](https://console.cloud.google.com/iam-admin/serviceaccounts/)
 to perform the deployment with the right permissions
Here are the list of service account:

Generation of keys file:

```bash
gcloud iam service-accounts keys create key.json --iam-account=<ACCOUNT>
```

In this example the key is stored in key.json.
The name of this file must be in `gcp_credentials_file_path`
