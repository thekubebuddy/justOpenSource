Table of content
==================
* [Vault dev setup - to get started](#starting-the-dev-vault-server-on-localhost)
* [Vault kv engine with custom path and usecase of it within k8s pod](#vault-kv-engine-with-custom-path--usecase-within-k8s)
* [Configuring vault with the GCP secret engine](#configuring-vault-with-the-gcp-secret-engine)
* [Deploying Vault on GCE with terraform](#deploying-vault-on-gce-with-terraform)
* [Generating vault token binded to specific access policies](#generating-vault-token-binded-to-specific-gcp-roleset-path)
* [Generating the root token in case loss or revoked](#generating-the-root-token-in-case-loss-or-revoked)
* [Vault cheetsheet](#vault-cheetsheet)


### Starting the dev-vault server on localhost
```bash
#Vault download: https://www.vaultproject.io/downloads
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200

# vault cli auto-completion
complete -C $(readlink -f $(which vault)) vault

export VAULT_ADDR="http://0.0.0.0:8200"
export VAULT_TOKEN=""
```

### Vault "kv" engine with custom path & usecase within k8s
* **Application:** Storing the postgresql admin password for different dbs in different env. in vault and fethching from the k8s psql pod

```bash
# enabling the vault kv secret engine with the postgresql path
vault secrets enable -path="postgresql" kv
vault secrets list

# inserting the secrets at specified path
vault kv put postgresql/secrets/pre-prod/pg-db01 pg_passwd=admin123
vault kv put postgresql/secrets/pre-prod/pg-db02 pg_passwd=admin123

# list and reading the vaules
vault kv list postgresql/secrets/pre-prod
vault kv get postgresql/secrets/pre-prod/pg-db01
vault read -format json postgresql/secrets/pre-prod/pg-db01 | jq ".data.pg_passwd"
```

* YAML spec for the consul-template init container.

Refer the `k8s-vault-secret-app.yaml` for more understanding
```bash
...

            template {
              contents = <<EOH
            {{- with secret "postgresql/secrets/pre-prod/pg-db01" }}
            export PG_PASSWD={{ .data.pg_passwd }}
            {{- end }}
            EOH
              destination = "/etc/secrets/pg-passwd"
            }
...
...
 args: ["/bin/sh", "-c","source /etc/secrets/pg-passwd && <main-process>"]
```


### Enabling the userpass engine
```bash
vault auth list
vault auth enable -path=training-userpass -description="userpass at a different path" userpass
vault auth enable -path=userpass -description="userpass at a different path" userpass
#Path-help
vault path-help userpass
vault write sys/auth/my-auth type=userpass
```




### Configuring vault with the GCP secret engine
* **Usecase:** Getting the GCP IAM SA access token from the specific GCP roleset through the vault provider and passing it to the GCP terraform provider for allowing authentication for tf workflows  

1. Enabling the google secret engine
```bash
vault secrets enable gcp
```

2. configuring the vault google secret engine with the root SA with the **"Service Account Admin", "Service Account Key Admin", "Project IAM Admin"** roles
```bash

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

```bash
vault write gcp/config credentials=@sa.json ttl=3600 max_ttl=86400
```

3. Roleset creation for token & SA key creation, this will create secondary SA which is created by the root auth
```bash
project=`gcloud config get-value project`
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

4. List, Read, Create the token, SA keys from those SA
```
vault read gcp/roleset/terraform-gcp-roleset
vault read gcp/token/terraform-gcp-roleset
vault list gcp/roleset/ 
vault delete gcp/roleset/terraform-gcp-roleset
```


5. GCP API call with the OAuth Barear token
```
curl -i "https://container.googleapis.com/v1beta1/projects/<project-id>/locations/us-central1/serverConfig?alt=json&prettyPrint=false" --header 'authorization: Bearer ya29.c.sOnFxokknu-3AxWa2CQKDXTPI9Si0QVvVmPyVasdadvSfyAtCkekQdYbI5mVJNn-adasdasdaa'     --header 'Content-Length: 0'
```




### Deploying Vault on GCE with terraform 
```bash
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


### Generating vault token binded to specific GCP roleset path

* For the demonstration, the GCP secret engine must be enabled & configured
* Relation between a token & how RBAC works for the vault
```
vault token <--> policy <---> capabilities(permissions) 
```

1. Creating a policy which contains the capabilities.
```
vault policy write dev01-secrets-policy  dev01_secrets_policy.hcl
```

2. Binding & token creation with the above policies`(without any default policy attached)`
```
vault token create -display-name=dev01-vault-token -ttl=0 -max-ttl=0  -policy=dev01-secrets-policy  -no-default-policy

# in case of any help
vault token create --help
```

3. Testing the above vault token
```bash
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


### Generating the root token in case loss or revoked.
* Regeneration of the root token is only possible if you got the unseal keys in place

```bash
vault status

# will ask for the unseal keys
#returns Nonce,otp: 
vault operator generate-root -init

# returns: encoded-token
vault operator generate-root

4. vault operator generate-root -decode=<encoded-token> -otp=<otp-generated-in-the-step-2>
```


### Vault cheetsheet
```bash
#https://www.vaultproject.io/docs/commands#vault_token
complete -C /usr/bin/vault vault
export VAULT_CACERT=""
export VAULT_ADDR=""
export VAULT_TOKEN=""

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



#### References
```

# terraform provider for vault
https://registry.terraform.io/providers/hashicorp/vault/latest/docs

# skipping built-in policies for the token generation
https://www.vaultproject.io/docs/concepts/tokens#explicit-max-ttls
https://www.vaultproject.io/docs/concepts/policies#built-in-policies
https://www.vaultproject.io/docs/concepts/tokens#periodic-tokens

https://learn.hashicorp.com/tutorials/vault/generate-root#use-one-time-password-otp
https://learn.hashicorp.com/tutorials/vault/rekeying-and-rotating
https://medium.com/google-cloud/vault-auth-and-secrets-on-gcp-51bd7bbaceb

# Configuring the vault gcp secrets engine
https://www.vaultproject.io/docs/secrets/gcp#google-cloud-secrets-engine


# Rotating the GCP service account keys: 
https://www.vaultproject.io/api-docs/secret/gcp#rotate-root-credentials
https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes


```


