# token polices which are necessary
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew" {
  capabilities = ["update", "create"]
}
path "auth/token/lookup-accessor" {
  capabilities = [ "read", "update" ]
}
# token will be able to read the roleset oauth tojeb
path "gcp/token/stg01-*" {
    capabilities = ["read"]
}

# the token binded to this policy will only be able to list & read the roleset at path gcp/roleset/dev01-* 
path "gcp/roleset/dev01-*" {
    capabilities = ["read","list"]
}

# also be able to list the rolesets from the gcp/roleset/*
path "gcp/roleset/*" {
    capabilities = ["list"]
}


