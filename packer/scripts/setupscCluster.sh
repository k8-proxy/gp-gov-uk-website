cluster=$(cat /home/ubuntu/cluster.txt)
monitoring_username=$(cat /home/ubuntu/monitoring-username.txt)
monitoring_password=$(cat /home/ubuntu/monitoring-password.txt)
logging_username=$(cat /home/ubuntu/logging-username.txt)
service_cluster=$(cat /home/ubuntu/service-cluster.txt)
sed -i "s|8.8.8.8|$(cat /home/ubuntu/service-cluster-ip.txt)|" /home/ubuntu/wc-coredns-configmap.yml
kubectl apply -f /home/ubuntu/wc-coredns-configmap.yml
kubectl delete pod --namespace kube-system --selector k8s-app=kube-dns
cat /home/ubuntu/cluster.txt | xargs -I {} kubectl patch prometheuses.monitoring.coreos.com kube-prometheus-stack-prometheus -n monitoring --type='json' -p '[{"op": "replace", "path": "/spec/externalLabels/cluster", "value":"'{}'"}]'
echo "https://influxdb.${service_cluster}/api/v1/prom/write?db=workload_cluster&u=${monitoring_username}&p=${monitoring_password}" > /home/ubuntu/influxdb-url.txt
cat /home/ubuntu/influxdb-url.txt | xargs -I {} kubectl patch prometheuses.monitoring.coreos.com kube-prometheus-stack-prometheus -n monitoring --type='json' -p '[{"op": "replace", "path": "/spec/remoteWrite/0/url", "value":"'{}'"}]'
kubectl delete pod -n monitoring prometheus-kube-prometheus-stack-prometheus-0
kubectl get cm -n fluentd fluentd-fluentd-elasticsearch -o yaml | sed 's/CLUSTER_NAME/'"${cluster}"'/' | kubectl apply -f -
kubectl get cm -n kube-system fluentd-system-fluentd-elasticsearch -o yaml | sed 's/CLUSTER_NAME/'"${cluster}"'/' | kubectl apply -f -
kubectl set env daemonset.apps/fluentd-fluentd-elasticsearch -n fluentd OUTPUT_HOSTS=elastic.${service_cluster}
kubectl set env daemonset.apps/fluentd-system-fluentd-elasticsearch -n kube-system OUTPUT_HOSTS=elastic.${service_cluster}
kubectl set env daemonset.apps/fluentd-fluentd-elasticsearch -n fluentd OUTPUT_USER=${logging_username}
kubectl set env daemonset.apps/fluentd-system-fluentd-elasticsearch -n kube-system OUTPUT_USER=${logging_username}
printf $(cat /home/ubuntu/logging-password.txt) | base64 | xargs -I {} kubectl patch secret -n fluentd elasticsearch --type='json' -p '[{"op": "replace", "path": "/data/password", "value":"'{}'"}]'
printf $(cat /home/ubuntu/logging-password.txt) | base64 | xargs -I {} kubectl patch secret -n kube-system elasticsearch --type='json' -p '[{"op": "replace", "path": "/data/password", "value":"'{}'"}]'
kubectl delete pod --namespace fluentd --selector app.kubernetes.io/instance=fluentd

> /home/ubuntu/monitoring-username.txt
> /home/ubuntu/monitoring-password.txt
> /home/ubuntu/logging-username.txt
> /home/ubuntu/logging-password.txt
> /home/ubuntu/service-cluster.txt
> /home/ubuntu/service-cluster-ip.txt
> /home/ubuntu/cluster.txt