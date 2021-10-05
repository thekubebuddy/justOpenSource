Elasticsearch 
1. Installation of specific elasticsearch version on the GCE(Centos 7)
2. Setting up the 2xNodes Elasticsearch cluster with 2 nodes(1xmaster, 1xdata)
3. Elasticsearch cheetsheet


### Installation of the Elasticsearch(v6.6.1)
Step1. GCE VM creations

```bash
# VM config:
# Size: e2-small(2cpu,2gb)
# Base image: centos7

gcloud compute instances create instance-es-2 --project=${PROJECT_NAME} --zone=asia-south1-a --machine-type=e2-small --network-interface=subnet=${SUBNET_NAME},no-address --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=${SA_ACCOUNT_ID} --scopes=https://www.googleapis.com/auth/cloud-platform --tags=allow-iap-access --create-disk=auto-delete=yes,boot=yes,device-name=instance-es-1,image=projects/centos-cloud/global/images/centos-7-v20210916,mode=rw,size=20,type=projects/${PROJECT_NAME}/zones/asia-south1-a/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
```


Step 2. SD agent installation(On Both VMs-Optional)
```bash
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh && sudo bash add-monitoring-agent-repo.sh --also-install && sudo service stackdriver-agent start
sudo systemctl enable stackdriver-agent
```

Step 3. ES installation(On Both VMs)

3.1 Installing the openjdk and few snip-ping
```bash
sudo yum -y install java-1.8.0-openjdk  java-1.8.0-openjdk-devel telnet jq
```
3.2 Adding the repo for the elastic yum repo

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/oss-6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
```

3.3 Installation of the Elasticsearch(v6.6.1)
```bash
#listing all of the packages in the elasticsearch repo
sudo yum repolist
sudo yum --enablerepo=elasticsearch-6.x --showduplicates list elasticsearch-oss

# installing specific v6.6.1
sudo yum -y install elasticsearch-oss-6.6.1
```

3.4 Changing the jvm param. as per machine size

```bash
sudo vi /etc/elasticsearch/jvm.options
-Xms512m
-Xmx512m
```

3.5 Enabling the elasticsearch service
```bash
sudo systemctl enable --now elasticsearch
sudo systemctl status  elasticsearch

# checking the logs
tail -f /var/log/elasticsearch/my-es-cluster.log 

# checking the status
curl http://127.0.0.1:9200 

# Index creation
curl -X PUT "http://127.0.0.1:9200/test_index"
```

>Index basically is a collection of the documents


### Setting up the Elasticsearch cluster with 2 nodes(1xmaster, 1xdata)

Step 4. Configuring the master-slave ES cluster(once installation done):

4.1 Taking the backup of the existing ES configs
```
sudo cp /etc/elasticsearch/{elasticsearch.yml,elasticsearch.yml.bckup}
```

4.2 Firewall rule config for `allowing 9300,9200 in between the es-nodes`

4.3. set the following attributes in the `/etc/elasticsearch/elasticsearch.yml`

* For the master-node:
```bash
cluster.name: my-es-cluster
node.name: master-node
network.host: [10.80.2.15,127.0.0.1]
http.port: 9200
discovery.zen.ping.unicast.hosts: [10.80.2.16, 10.80.2.15]
discovery.zen.minimum_master_nodes: 1
```

* For the data-node-1:
```bash
cluster.name: my-es-cluster
node.name: master-node
network.host: [10.80.2.16,127.0.0.1]
http.port: 9200
```
> The configs files for the master and data-node are saved as es-master.yml, es-data1.yml

* Restart the service on data-nodes(slave-nodes) first and then master
```bash

sudo systemctl restart elasticsearch
sudo systemctl status elasticsearch

# checking the logs
tail -f /var/log/elasticsearch/my-es-cluster.log 

# check the nodes connected into the cluster
curl 127.0.0.1:9200/_cat/nodes?v
```

5. Verifying the data replication across the Cluster

* Storing the document on the master-node in the car index:
```bash
curl -XPUT -H "Content-Type: application/json" 'localhost:9200/car/_doc/1?pretty' -d '
{
"model": "Porshe",
"year": 1972,
"engine": "2.0-liter four-cylinder Macan",
"horsepower": "252hp",
"genres": ["Sporty", "Classic"]
}'
```

* Retriving it on the data-node-1
```bash
curl -X GET -H "Content-Type: application/json" 'localhost:9200/car/_doc/1'
```



### Elasticsearch cheetsheet[API Calls]
```bash
# Getting the cluster info
curl http://127.0.0.1:9200 

# Get the nodes information in the cluster
curl 127.0.0.1:9200/_cat/nodes?v
curl -sXGET 'http://localhost:9200/_cluster/state?pretty' | jq .nodes


# Index creation, where "test_index" is the index name
curl -X PUT "http://127.0.0.1:9200/test_index"

# Storing the documents into the Index. "car" is the index name
curl -XPUT -H "Content-Type: application/json" 'localhost:9200/car/_doc/1?pretty' -d '
{
"model": "BMW",
"year": 1972,
"engine": "2.0-liter four-cylinder Macan",
"horsepower": "252hp",
"genres": ["Sporty", "Classic"]
}'

# retriving a particular document stored in the "car" index
curl -sX GET -H "Content-Type: application/json" 'localhost:9200/car/_doc/1' | jq

# getting the document count for the car index
curl -sX GET -H "Content-Type: application/json" 'http://localhost:9200/car/_count?q=*' | jq

# getting all of the documents for the car index
curl -sX GET -H "Content-Type: application/json" 'http://localhost:9200/car/_search?pretty=true&q=*:*' | jq

# Getting the size of all of the index'es stored in the elasticsearch
curl -sX GET -H "Content-Type: application/json" 'http://localhost:9200/_cat/indices?v'
curl -sX GET -H "Content-Type: application/json" 'http://localhost:9200/_cat/indices?h=index,store.size&bytes=kb&format=json' | jq .
## ^^ will return the index name and size in kb


# Getting the cumulative size for all of the indices 
curl -s 'http://localhost:9200/_cat/indices?bytes=kb'| tr -s ' ' | cut -f9 -d" " | awk '{s+=$1} END {print s}'
``` 



References
```
https://ostechnix.com/list-installed-packages-certain-repository-linux/
https://discuss.elastic.co/t/what-are-ports-9200-and-9300-used-for/238578
https://logz.io/blog/elasticsearch-cluster-tutorial/
https://computingforgeeks.com/how-to-install-elasticsearch-on-centos/
https://stackoverflow.com/questions/47544966/content-type-header-application-x-www-form-urlencoded-is-not-supported-on-elas
https://kb.objectrocket.com/elasticsearch/guide-how-to-add-documents-to-an-index-in-elasticsearch
```