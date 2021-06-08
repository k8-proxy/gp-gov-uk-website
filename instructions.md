# Deploy GW Cloud SDK with compliant kubernetes (worker and service cluster)

## Prerequisites

-  One aws `key-pair` in respective region

## Deployment instructions using AMI

Worker and service cluster AMIs are automatically created by running **CK8icap-GW_CloudSDK** workflow in GitHub Actions using Packer.
Amazon CloudFormation launch Template is provided  in the repository to facilitate configuration of the deployment.

- To launch instances click on one of the Buttons below and follow the steps


### Launching with Click of Button
| Region           | Stack                                                                                                                                                                                                                                                                                                                                      |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Ireland          | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) |
| London          | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=eu-west-2#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) |
| Frankfurt          | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) |
| Paris          | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=eu-west-3#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) |
| Ohio  | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) | 
| N. Virginia  | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) | 
| N. California  | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=us-west-1#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) | 
| Oregon  | [<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" />](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=IcapLoadBalancerStack&templateURL=https://icap-cloudformation-template.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) | 



* When prompted with the image below, click Next

  ![Screenshot from 2021-03-25 17-13-06](https://user-images.githubusercontent.com/7603614/112506566-2fb20380-8d8e-11eb-9476-909cc8a751ed.png)

* Enter `Stack name` (less than 20 characters)

  ![Screenshot from 2021-03-25 17-13-45](https://user-images.githubusercontent.com/7603614/112506657-45bfc400-8d8e-11eb-91a9-59e3c0b558ef.png)

  Set **Credentials**:

  * `Service Cluster Key Name` and `Workload Cluster Key Name` to the names of key pairs (previously uploaded to AWS) that will be allowed to SSH into VMs

    ![Screenshot from 2021-03-25 17-14-04](https://user-images.githubusercontent.com/7603614/112506741-55d7a380-8d8e-11eb-8627-8427d194eeed.png)

  * `Logging Password`  Fluentd password

  * `Monitoring Password` to plain text of InfluxDB WC writer password

    The **Logging Password** & **Monitoring Password** are the elasticsearch.fluentdPassword & influxDB.wcWriterPassword Values respectively that are generated during the github action run which produced the used service cluster AMI

    ![pic2](https://user-images.githubusercontent.com/70108899/116323434-3fbe6800-a7be-11eb-975b-592d81187897.jpg)

    
  
  * **Service Cluster** specification mainly AMI ID and Instance size, make sure the AMI is the one generated in the same github action run where you get the logging and monitory passwords above.

    ![image](https://user-images.githubusercontent.com/17300331/116555949-8fb24180-a91a-11eb-8e1c-4bb506755a86.png)

  * **Workload Cluster** specification mainly AMI ID, Instance size and number of instances.

    ![image](https://user-images.githubusercontent.com/17300331/116556059-af496a00-a91a-11eb-8367-a03373ad08e2.png)


* When the stack creation is complete, in the **Outputs** tab you can find:
  * `Load Balancer DNS Name` which stand in-front of the workload cluster instances and accept requests on port `8080`
  * `Service Cluster IP`  that exposes Grafana on port `3000` and Kibana on port `5601`

  ![Screenshot from 2021-03-25 18-05-43](https://user-images.githubusercontent.com/7603614/112513618-ced9f980-8d94-11eb-9559-61cee07e7a93.png)


## Testing

* Testing workload cluster :

  * To check API health, from Browser access `<LoadBalancer DNS Name>/api/health` and verify its ok

    ![image](https://user-images.githubusercontent.com/70108899/116484783-179c3b00-a88a-11eb-9c79-c70e10847bed.png)

  * To rebuild files, from Browser access Filedrop `<LoadBalancer DNS Name>` and select any file you want to rebuild 
  * After file is rebuilt you will be able to download protected file along with XML report

    ![image](https://user-images.githubusercontent.com/70108899/116483290-13225300-a887-11eb-9187-2327fc559a47.png)

* Testing service cluster :

  * From your browser go to service cluster IP provided in the outputs tab above on port 3000 to access Grafana and on port 5601 to access Kibana

  * **Grafana's Password** & **Kibana's Password** are the user.grafanaPassword & elasticsearch.adminPassword Values respectively that are generated during the github action run which produced the used service cluster AMI

    ![pic1](https://user-images.githubusercontent.com/70108899/116323389-29181100-a7be-11eb-8fb4-5e8581e1b9db.jpg)
    
  * For Elastic from browser navigate to `http://<SC VM IP>:5601`
   - From settings choose `Discover` and select one of three options for logs (kubespray*, kubernetes* or other*)
   
        ![image](https://user-images.githubusercontent.com/70108899/116484905-53370500-a88a-11eb-8477-d55c1db73519.png)
        
   - From settings choose `Dashboard` and select one of two available or create custom one. This option will give you more of a grafical overview compared to `Discover`
   
        ![image](https://user-images.githubusercontent.com/70108899/116485151-cf314d00-a88a-11eb-99d7-b5a7e1d15a91.png)
     
  * For Grafana from browser navigate to `http://<SC VM IP>:3000`

   - Click on `Search` and type `Kubernetes / Compute Resources / Namespace (Pods)` and select the dashboard from search result

        ![image](https://user-images.githubusercontent.com/64204445/116515131-85c41a80-a8e9-11eb-9d98-cf26f9b6f4e4.png)
        
   - Here you can switch between Workload clusters and also namespaces to see metrics
   
        ![image](https://user-images.githubusercontent.com/64204445/116515563-14d13280-a8ea-11eb-900b-58fe934cad07.png)


   - `ck8s-metrics` data set is added and you can use it when creating custom dashbords
  
        ![image](https://user-images.githubusercontent.com/70108899/116485399-65fe0980-a88b-11eb-84ba-0d4e7d77c379.png)
