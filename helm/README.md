Table of Content
========================

* What and why is helm
* Helm installation
* Helm cheetsheet

















What and why is helm
 
An OS Package managemer Roles:
 * Provides automatic installation, Version controlled, Dependency management, Automated removal of the software within the System.




* Helm Installation:

```
wget https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz
tar zxfv helm-v3.2.1-linux-amd64.tar.gz
cp linux-amd64/helm .

# for the helm v2.14
helm init 
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p'{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```


For getting info about the charts repositories and there indexes.  
```
helm home 
```

index.yaml is the important file 

For adding a helm repo
```
helm repo add <repo-name> <indem>
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```
1. Helm takes the context from the kubectl config for the installation 


* Helm Cheetsheet(3.3+)
```
helm version --short

# autocompletion
source <(helm completion bash) 

#listing out all of the releases
helm list 

#listing out all of the releases, one's that being failed
helm list -a 

# search for a chart named wordpress in the helm added repository
helm search repo wordpress 
helm search repo wordpress --version

# list all of the available chart present in the hashicorp repo
helm search repo hashicorp

helm search repo hashicorp/vault --vesions

# install wordpress(v5.0.1) chart from the stable repository with different 
release name
helm install stable/wordpress --version 5.0.1 --namespace=wordpress --create
helm install vault hashicorp/vault --set "server.dev.enabled=true"

# deleting a release
helm delete <release-name> 

# upgrade the release chart with the latest one
helm upgrade <release-name> stable/wordpress -f value.yaml

# history of a helm release for rollback
helm history
helm rollback wordpress-app 1

# getting the deployed yamls for a particular release
helm get manifest wordpress-release

# listing out all of the dependencies for the helm charts which are mentioned in the requirement.yaml
helm dep list 

# downloads the latest jenkins chart from the helm repo
helm pull stable/jenkins --untar --version=1.1.4

# dryrunning the template & generating the templates with the values.yaml input.
helm install appchart . --namespace test-ns --create-namespace 
helm install appchart .  --dry-run --debug

#v2.14
helm install --name <release-name> <chart-name>
```