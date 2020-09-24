# ArgoCD 

Table of content
======================
1. [Adding user's to the argocd](#1-adding-users-to-the-argocd)
2. [Enforcing readonly policy to the newly created user](#2-enforcing-readonly-policy-to-the-newly-created-user)




### 1. Adding users to the argocd

* Each argocd user might have two capabilities:
    * apiKey - allows generating authentication tokens for API access
    * login - allows to login using UI


* Update the `argocd-cm` with the following 
```
accounts.alice: apiKey, login
accounts.bob: login
```

* Setting the password for the alice user
```
# Login to the CLI with admin user 

$ argocd account update-password --account alice --current-password <admi-user-password> --new-password <new-password-to-set>

$ argocd account list

# Generating the auth token
$ argocd account generate-token --account <username> 

```

### 2. Enforcing readonly policy to the newly created user

* Once user gets added, readonly policy can be enforced using the `below argocd-rbac-cm` changes.
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  # enforcing readonly policies for all of the users
  policy.default: role:readonly
```




### References
https://argoproj.github.io/argo-cd/operator-manual/user-management/
https://argoproj.github.io/argo-cd/operator-manual/rbac/#tying-it-all-together
https://argoproj.github.io/argo-cd/faq/



