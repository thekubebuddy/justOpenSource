* Its a Declarative Application management tool (supported onwards 1.14+)
* Its simple nd easy to manage yaml, **no templating** at all required for managing.
* Makes the reuse of the yaml's for different env. more easy and efficient
* No need to make any changes to the exitsing yaml resources, all you need to add **kustomization.yaml** into 
the directoty
* Its has a base and overlay structure in which we can use the bases for multiple in
* It has many heplful **directives** which makes our task much more easy:

Some of the common directives/fields in kustomization yaml:
1. **resources**
2. **bases**
3. **namespace**
4. **namePrefix and nameSuffix**
5. **image**
6. **pathcesStrategicMerge**
6. configMapGenerator


commands
```
kustomize build .
```

Refrences:
[Kustomization CLI installation](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md)s
[Kustomize: Kubernetes Configuration Customization](https://www.youtube.com/watch?v=WWJDbHo-OeY)
[Kubernetes-SIG](https://github.com/kubernetes-sigs/kustomize)
[\*\*Kustomization fields](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/fields.md)
[Wordperss Example of kustomization](https://github.com/kubernetes-sigs/kustomize/tree/master/examples/wordpress)
https://kubectl.docs.kubernetes.io/pages/app_management/introduction.html