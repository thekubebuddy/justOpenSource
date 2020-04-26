Monitoring system
SoundCloud 2012 CNCF


Architectural component:
1. Client library 
2. Exporter(MySql exporter, node expoter, haProxy exporter)
3. Service Discovery
4. 


Step1. Installed the prometheus, do change the private ip's address in the prometheus conf.
Step2. Varify all of the targets under the target tabs
Step3. Configuring the grafana and ad (3.1.1




Node Exporter Installation:

```
adduser prometheus


cd /home/prometheus
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz"
tar -xvzf node_exporter-0.16.0.linux-amd64.tar.gz
mv node_exporter-0.16.0.linux-amd64 node_exporter
cd node_exporter
chown prometheus:prometheus node_exporter


vi /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target


systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
```


Container CPU load average:
```
container_cpu_load_average_10s
```
Getting the memory usage for our node:
```
((sum(node_memory_MemTotal_bytes) - sum(node_memory_MemFree_bytes) - sum(node_memory_Buffers_bytes) - sum(node_memory_Cached_bytes)) / sum(node_memory_MemTotal_bytes)) * 100
```
