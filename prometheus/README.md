Monitoring system
SoundCloud 2012 CNCF


Architectural component:
1. Client library 
2. Exporter(MySql exporter, node expoter, haProxy exporter)
3. Service Discovery
4. 


Step1. Installed the prometheus, do change the private ip's address in the prometheus conf.
Step2. Varify all of the targets under the target tabs
Step3. Configuring the grafana and ad (3.1.1)




### Deploying Node exporter as a daemonset on the kubernetes nodes:

1. Deploy the yaml
```
k apply -f prometheus-config-map.yml
```


2. Port-forward the ds and curl the endpoints
```
k port-forward ds/node-exporter 9100:9100
```

3. Curl the localhost and verify the /metrics
![node_exporter](pic/node-exporter-1.png)



### Node Exporter Installation On hard-VM's and configuring it with the prometheus:

1. Add a User prometheus

```
adduser prometheus

cd /home/prometheus
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz"
tar -xvzf node_exporter-0.16.0.linux-amd64.tar.gz
mv node_exporter-0.16.0.linux-amd64 node_exporter
cd node_exporter
chown prometheus:prometheus node_exporter
```

2. Create a prometheus service file
```
vi /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target
```

3. Reload and enable the node_exporter service on the host
```
systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
```

4. If all installation is done correctly we can curl and verify whether the metrics exported by node-exporter 
```
curl http://<node-private-ip>:9100/metrics
```

5. If the above step is properly executed, than add an entry for that host private ip into the 'prometheus-config-map-2.yml'


PromQL:

Container CPU load average:
```
container_cpu_load_average_10s
```
Getting the memory usage for our node:
```
((sum(node_memory_MemTotal_bytes) - sum(node_memory_MemFree_bytes) - sum(node_memory_Buffers_bytes) - sum(node_memory_Cached_bytes)) / sum(node_memory_MemTotal_bytes)) * 100
```

https://github.com/shevyf/minikube-prometheus-demo