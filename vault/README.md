
**Starting the dev-vault server on localhost:**
```
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200
complete -C $(readlink -f $(which vault)) vault

export VAULT_ADDR="http://0.0.0.0:8200"
```


**Enabling the userpass engine:**
```
vault auth list
vault auth enable -path=training-userpass -description="userpass at a different path" userpass
vault auth enable -path=userpass -description="userpass at a different path" userpass
```

**Path-help**
``` 
vault path-help userpass
```

OR
```
vault write sys/auth/my-auth type=userpass
```

Recovery Key Rekeying
vault operation rekey -target=recovery

Revokation of the vault 
```
vault lease revoke
```



Vault secret engine example:
```
vault kv put secret/devwebapp/config username='giraffe' password='salsa'
vault read -format json secret/data/devwebapp/config | jq ".data.data"
```


Rotating the GCP service account keys: 
https://www.vaultproject.io/api-docs/secret/gcp#rotate-root-credentials

https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes



## Configuring vault with the GCP secret engine


1. Enabling the google secret engine
```
vault secrets enable gcp
```

2. configuring the vault google secret engine with the root SA with the **"Service Account Admin", "Service Account Key Admin", "Project IAM Admin"** roles
```

PROJECT_ID=`gcloud config get-value project`
SERVICE_ACCOUNT_NAME=vault-admin-roleset-sa
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role="roles/iam.serviceAccountAdmin" 


gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role="roles/iam.serviceAccountKeyAdmin" 


gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role="roles/resourcemanager.projectIamAdmin"


gcloud iam service-accounts keys create --iam-account ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com ./sa.json
```

```
vault write gcp/config credentials=@sa.json ttl=3600 max_ttl=86400
```

3. roleset creation for token & SA key creation, this will create secondary SA which is created by the root auth
```
project=""
vault write gcp/roleset/terraform-gcp-gcs-admin-roleset \
        token_scopes="https://www.googleapis.com/auth/cloud-platform" \
        project=$project \
        secret_type="access_token" \
    bindings=-<<EOF
      resource "//cloudresourcemanager.googleapis.com/projects/$project" {
        roles = ["roles/storage.admin"] # define the role for the SA which will be created by the vault
      }
EOF
```

4. list, read, create the token, SA keys from those SA
```
vault read gcp/roleset/terraform-gcp-roleset
vault read gcp/token/terraform-gcp-roleset
vault list gcp/roleset/ 
vault delete gcp/roleset/terraform-gcp-roleset
```


5. Sample API call with the OAuth Barear token
```
curl -i "https://container.googleapis.com/v1beta1/projects/<project-od>/locations/us-central1/serverConfig?alt=json&prettyPrint=false" --header 'authorization: Bearer ya29.c.sOnFxokknu-3AxWa2CQKDXTPI9Si0QVvVmPyVasdadvSfyAtCkekQdYbI5mVJNn-adasdasdaa'     --header 'Content-Length: 0'
```

Refrence:
https://www.vaultproject.io/docs/secrets/gcp#google-cloud-secrets-engine



## Deploying Vault on GCE with terraform 
```
gsutil cp -r gs://spls/gsp205 .
cd gsp205
unzip tf-google-vault.zip
cd terraform-google-vault/
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)
cat - > terraform.tfvars <<EOF
project_id = "${GOOGLE_CLOUD_PROJECT}"
kms_keyring = "vault"
kms_crypto_key = "vault-init"
EOF
terraform init
export VAULT_ADDR="$(terraform output vault_addr)"
export VAULT_CACERT="$(pwd)/ca.crt"
``` 


## Generating vault token binded to specific GCP roleset path

* For the below testing the GCP secret engine must be enabled & configured
* Relation between a token & how RBAC works for the vault
```
vault token <--> policy <---> capabilities(permissions) 
```

1. Creating a policy which contains the capabilities.
```
vault policy write dev01-secrets-policy  dev01_secrets_policy.hcl
```

2. Binding & token creation with the above policies(without any default policy attached)
```
vault token create -display-name=dev01-vault-token -ttl=0 -max-ttl=0  -policy=dev01-secrets-policy  -no-default-policy

# in case of any help
vault token create --help
```

3. Testing the above vault token
```
# login with the above token generated
vault login 

vault token lookup 

vault list gcp/roleset/ //allowed
vault read gcp/roleset/dev01-tf-viewer-roleset-2 //allowed

# getting the token also allowed
vault read gcp/token/dev01-tf-viewer-roleset //allowed

vault read gcp/roleset/stg01-tf-viewer-roleset //forbidded
```

4. For revoking the token
```
vault token revoke <token>
```


## Generating the root token in case loss or revoked.
* Regeneration of the root token is only possible if you got the unseal keys in place

```
vault status

# will ask for the unseal keys
vault operator generate-root -init
returns Nonce,otp: 

vault operator generate-root
returns: encoded-token

4. vault operator generate-root -decode=<encoded-token> -otp=<otp-generated-in-the-step-2>
```
## Vault cheetsheet
```
complete -C /usr/bin/vault vault
export VAULT_CACERT=""
export VAULT_ADDR=""

# vault initializing status
vault operator init -recovery-shares 5 -recovery-threshold 3
# vault is initialized or not
vault operator init -status
# for sealing & unsealing the vault
vault operator seal
vault operator unseal
# vault secrets engine
vault secrets list
vault secrets enable kv
```



### References
```
# vault provider for the terraform
https://registry.terraform.io/providers/hashicorp/vault/latest/docs
https://www.vaultproject.io/docs/concepts/tokens#explicit-max-ttls
https://www.vaultproject.io/docs/concepts/policies#built-in-policies
https://www.vaultproject.io/docs/concepts/tokens#periodic-tokens
https://learn.hashicorp.com/tutorials/vault/generate-root#use-one-time-password-otp
https://learn.hashicorp.com/tutorials/vault/rekeying-and-rotating
```

