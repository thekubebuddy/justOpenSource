#### Installation of the istio
```bash
# for listing all of the available profiles
istioctl profile list

# install the istio operator within the namespace
istioctl operator init
istioctl operator remove
# create the "IstioOperator" CRD yaml and apply to the GKE cluster, istio operator will pick up the YAML
# and deploy the istio control plan 


# getting the istiooperator status
kubectl get istiooperator -n istio-system

#
kubectl label ns test-ns istio-injection=enabled
kubectl label ns test-ns istio-injection-

```

* Changes for the private GKE cluster
```
export CLUSTER_NAME=
gcloud compute firewall-rules list --filter="name~gke-${CLUSTER_NAME}-[0-9a-z]*-master"
gcloud compute firewall-rules update <firewall-rule-name> --allow tcp:10250,tcp:443,tcp:15017
```

* Getting the proxyconfig from the isitio-envoy enabled pod
```bash
istioctl proxy-config secret nginx-dd4b8b788-h59zp -o json

openssl x509 -text -noout -in base64EncodeCA.crt 

curl -v http://dev.hello-world.com
curl -s -I http://dev.hello-world.com
```

#### Types of  Resources in istio
```
1. Isitio ingress gateway - Loadbalancer type svc set-up in the isitio-system namespace 
2. Isitio egress gateway
3. Virtual services # bounds the istio ingress gateway with the virtual service
4. Destination rules
5. WorkloadEntry & ServiceEntry
6. Sidecar resource # for the custom sidecar egress & ingress configs

```

```
Istio-ingress-gateway <--> virtual services --->  Subnets & destination rule
```
Reference:
```
https://istio.io/latest/docs/setup/platform-setup/gke/
https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#configuring-ingress-using-an-istio-gateway
```