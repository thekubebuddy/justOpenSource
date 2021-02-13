
Starting the dev-vault server on localhost:
```
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200
complete -C $(readlink -f $(which vault)) vault
```


Enabling the userpass engine:
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



## Configuring the vault with the *GCP secret engine*


1. Enabling the google secret engine
```
vault secrets enable gcp
```

2. configuring the vault google secret engine with the root SA with the "Service Account Admin", "Service Account Key Admin", "Project IAM Admin" roles
```

PROJECT_ID=<project-id>
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