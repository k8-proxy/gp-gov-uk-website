# Instructions to integrate Service Cluster and Workload Cluster of Complaint K8 Cloud SDK
- Login to virtual machine using SSH and navigate to `/home/ubuntu` and switch to root by `sudo su`
- Verify presence of below files by issuing command `ls`
   ```
    /home/ubuntu/monitoring-username.txt
    /home/ubuntu/monitoring-password.txt
    /home/ubuntu/logging-username.txt
    /home/ubuntu/logging-password.txt
    /home/ubuntu/service-cluster.txt
    /home/ubuntu/service-cluster-ip.txt
    /home/ubuntu/cluster.txt
    /home/ubuntu/wc-coredns-configmap.yml
    /home/ubuntu/setupscCluster.sh
    ```
- Update each text file with corresponding values:
```
    monitoring-username.txt - wcWriter
    monitoring-password.txt - <Add monitoring password>
    logging-username.txt - fluentd
    logging-password.txt - <Add logging password>
    service-cluster.txt - ops.default.compliantkuberetes
    service-cluster-ip.txt - <service-cluster-ip>
    cluster.txt - <Unique Identifier of workload instance> E.g., GWSDKWC01
```
- Change permission of `setupscCluster.sh` by below command:
    `chmod +x setupscCluster.sh`
- Execute setupscCluster by below command:
    `./setupscCluster.sh`
- Wait for all commands to complete. Once completed, login to Grafana and Kibana in service cluster
    `http://<service-cluster-ip>:5601/  - Kibana`
    `http://<service-cluster-ip>:3000/  - Grafana`

    Username: `admin`
    Password: `Will be shared as part of delivery`