# ICAP Adaptation Service on Compliant Kubernetes

[Compliant Kubernetes](https://compliantkubernetes.io/) consists of two clusters:

* **workload cluster** hosting Glasswall's ICAP adaptation application and exporters for monitoring and logging data,
* **service cluster** hosting Complaint Kubernetes applications for monitoring, logging and vulnerability management, such as Kibana and Grafana.

## Deployment instructions

In this document we describe how to deploy Compliant Kubernetes setup on AWS.

Workload and service clusters serve different purposes, are deployed at different frequencies and have different expected lifetimes.
Therefore, they are deployed in different ways.

**Workload cluster** is deployed from an AMI, which is automatically created in by GitHub Actions using Packer.
Amazon EC2 Launch Template and CloudFormation Template are provided to facilitate configuration of the deployment.

Procution version of **Service cluster** is deployed from scratch using several scripts, including Terraform, Kubespray and Helm.

An additonal version of **Service cluster**, suitable for the development environment, is available as an AMI.
An instance of this version can be privisioned using Amazon EC2 Launch Template.

### Workload cluster

### Workload and Service cluster (Development version)

Use `Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json` CloudFormation template to deploy a number of Workload Clusters and a single Service Cluster.

| Region | Stack |
| --- | --- |
| Ireland | [![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/new?stackName=compliant-k8s-stack&templateURL=https://cf-templates-compliant-k8s-eu-west-1.s3-eu-west-1.amazonaws.com/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json) |

* Click on one of the buttons above depending on the region you want to work on
* When prompted with the image below, click Next

  ![Screenshot from 2021-03-25 17-13-06](https://user-images.githubusercontent.com/7603614/112506566-2fb20380-8d8e-11eb-9476-909cc8a751ed.png)

* Enter `Stack name`

  ![Screenshot from 2021-03-25 17-13-45](https://user-images.githubusercontent.com/7603614/112506657-45bfc400-8d8e-11eb-91a9-59e3c0b558ef.png)

  Set **Credentials**:

  * `Service Cluster Key Name` and `Workload Cluster Key Name` to the names of key pairs (previously uploaded to AWS) that will be allowed to SSH into VMs
  * `Logging Password` to Base64 encoded value of Fluentd password
  * `Monitoring Password` to plain text of InfluxDB WC writer password

  ![Screenshot from 2021-03-25 17-14-04](https://user-images.githubusercontent.com/7603614/112506741-55d7a380-8d8e-11eb-8627-8427d194eeed.png)

  Make sure that the following configuration parameters for **Load Balancer** are not used by other stacks in the AWS region:

  * `Load Balancer Name`
  * `Target Group Name`
  * `Elastic IP`

  ![Screenshot from 2021-03-25 17-14-34](https://user-images.githubusercontent.com/7603614/112506814-66881980-8d8e-11eb-9658-1a75fc15e043.png)

  You may also change:

  * **Service Cluster** specification
  * **Workload Cluster** specification including the number of Workload Cluster instances
  * **Docker Images** used for the Glasswall services

* When the stack creation is complete, in the **Outputs** tab you can find:
  * `Load Balancer DNS Name` that accept requests on port `1346`
  * `Service Cluster IP` that exposes Grafana on port `3000` and Kibana on port `5601`

  ![Screenshot from 2021-03-25 18-05-43](https://user-images.githubusercontent.com/7603614/112513618-ced9f980-8d94-11eb-9559-61cee07e7a93.png)

### Service cluster (Production version)

## Developing

### Update CloudFormation template

Create the S3 bucket (if does not exist already)

    aws s3 mb s3://cf-templates-compliant-k8s-eu-west-1 --region eu-west-1

Upload the CloudFormation template

    aws s3 cp Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json s3://cf-templates-compliant-k8s-eu-west-1/Compliant_Kubernetes_ICAP_Service_with_Service_Cluster_Proxy_REST_API.json

## OLD CONTENT

### Initialize the environment

Before the first deployment, you need to configure the whole environment.

1. Copy configuration and secret files from templates.

       cp setup-env.sh.example setup-env.sh
       cp secrets-env.sh.example secrets.sh

2. Set configuration parameters in `setup-env.sh` and `secrets.sh`.

3. Source your environment file

        source setup-env.sh

4. Initialize kubespray environment:

        cd compliantkubernetes-kubespray
        ./bin/ck8s-kubespray init sc default ~/.ssh/id_rsa.pub
        ./bin/ck8s-kubespray init wc default ~/.ssh/id_rsa.pub

5. Initialize Compliant Kubernetes:

        cd compliantkubernetes-apps
        ./bin/ck8s init

### Workload cluster

#### Deploying an instance from OVA

To deploy an instance from an existing OVA you can use the vSphere Client GUI.

1. Go to the `VMs and Templates` view.
2. Find the template and right click on it.
3. In the context menu choose `New VM from This Template...`
4. Give a nce to the new VM and click `Next`.
5. Select a compute resource and click `Next`.
6. Select storage and click `Next`.
7. Check `Power on virtual machine after creation` option and click `Next`.
8. Expand `Uncategorized` group, paste base64 encoded user data in `Encoded user-data` field, and click `Next`.

   * To modify the configuration of the new instance, edit `user-data.yml` file.

         cp user-data.yml.example user-data.yml

     Set values for:

        * [PUBLIC_SSH_KEY]
        * [IP_ADDRESS]
        * [MASK]
        * [GATEWAY]
        * [CLUSTER_NAME]
        * [MONITORING_USERNAME]
        * [MONITORING_PASSWORD] (plain text)
        * [LOGGING_USERNAME]
        * [LOGGING_PASSWORD] (base64 encoded)
        * [DOMAIN]
        * [SERVICE_CLUSTER]

   * To encode the file run:

         cat user-data.yml | base64 -w0

   * Copy the output and pate in the vSphere Client GUI.

9. Verify the configuration and click `Finish`.
10. The new VM will be created and started automatically (if you checked the appropiate box in step 7).
    It will be visible in the vSphere Client GUI.
11. NOTE: It might be necessary to ssh into the VM and run `/usr/bin/initconfig.sh` script as root. (Work in progress to fix this.)

#### Building an OVA using Packer

To build an OVA, follow the instructions in [VMware Packer](/vmware-scripts/packer/README.md) module.

### Service cluster

#### Create infrastructure

1. Move to the Terraform TFE directory

        cd ../ck8s-cluster/terraform/tfe

2. Export TF variables

        export TF_DATA_DIR=${CK8S_CONFIG_PATH}/.state/.terraform-tfe
        export TF_STATE=${CK8S_CONFIG_PATH}/.state/terraform-tfe.tfstate
        export TF_WORKSPACE=ck8s-ovh-glasswall-kubespray-jk-149

3. Create Terraform Workspace

        terraform init
        terraform apply -var organization=elastisys -var workspace_name=$TF_WORKSPACE

4. Create CK8s service cluster in vSphere

        cd ../vsphere/

    Set kubespray configuration following the [official instructions](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/vsphere.md)

        export TF_DATA_DIR=${CK8S_CONFIG_PATH}/.state/.terraform
        export TF_VAR_ssh_pub_key=~/.ssh/id_rsa.pub
        export TF_WORKSPACE=glasswall-kubespray-jk-149

        terraform init -backend-config ${CK8S_CONFIG_PATH}/backend_config.hcl

        terraform apply -target module.service_cluster

5. Update `inventory.ini` file in `sc-config` directory by setting `ansible_host` value to the Public IP address of the VM.

#### vSphere Storage Policy

Create a Storage Policy following the instructions [here](https://github.com/kubernetes/cloud-provider-vsphere/blob/master/docs/book/tutorials/kubernetes-on-vsphere-with-kubeadm.md#create-a-storage-policy)

1. Name and description

    Name: `Space-Efficient`

2. Policy structure

    Select `Enable host based rules`

3. Host based services

    Encryption, select: `Disabled`

    Storage I/O Control, select: `Normal IO share allocation`

4. Storage compatibility

    Make sure there is compatible storage available.

5. Click `Finish`

Configure VP Storage Policy for all the VMs:

1. Select the VM

2. Go to Configure tab

3. Click `EDIT VM STORAGE POLICIES`

4. Uncheck `Configure per disk` option

5. Select `Space-Efficient` value in the `VM storage policy` drop-down menu

6. Click `OK` button

#### Install Kubernetes

Run in `gp-gov-uk-website/compliantkubernetes-kubespray`

    cd ../../../compliantkubernetes-kubespray

1. Set the value of `supplementary_addresses_in_ssl_keys` field in `*c-config/group_vars/k8s-cluster/k8s-cluster.yaml` to the Public IP of respective master nodes (workload and service clusters).

2. Deploy Service Cluster:

        ./bin/ck8s-kubespray apply sc

#### Create vSphere CSI Storage Class

Run in `gp-gov-uk-website/compliantkubernetes-apps`

        cd ../compliantkubernetes-apps
        ./bin/ck8s ops kubectl sc create -f bootstrap/storageclass/manifests/vsphere-csi.yaml

#### Install Compliant Kubernetes

Follow the instructions in [README file](compliantkubernetes-apps/README.md)

        export CK8S_CLOUD_PROVIDER=baremetal
        export CK8S_FLAVOR=dev
        export CK8S_CONFIG_PATH=~/workspace/glasswall/gp-gov-uk-website/ovh_glasswall-kubespray-jk

        ./bin/ck8s apply sc

## Testing ICAP service

To test the ICAP service run the following command:

    c-icap-client -f /home/jakub/Downloads/FIVB_VB_Scoresheet_2013_updated2.pdf -i icap.glasswall-ck8s-proxy.com -p 1344 -s gw_rebuild -o ./rebuilt.pdf -v

To test the ICAP service with TLS run the following command:

    docker run -it --rm -v /home/jakub/Downloads:/opt -v /home/jakub/Downloads:/home glasswallsolutions/c-icap-client:manual-v1 -s 'gw_rebuild' -i icap-149.glasswall-ck8s-proxy.com -p 1345 -tls -tls-method TLSv1_2 -tls-no-verify -f '/opt/FIVB_VB_Scoresheet_2013_updated2.pdf' -o '/opt/rebuilt.pdf' -v

You can also use script in `icap-client-docker` project.

To send a single request to `icap-155.glasswall-ck8s-proxy.com` server run:

    ./icap-client.sh icap-155.glasswall-ck8s-proxy.com

To send 50 requests to `icap-149.glasswall-ck8s-proxy.com` server run:

    ./parallel-icap-requests.sh icap-149.glasswall-ck8s-proxy.com 50

## Update ICAP request processing

1. Move to `gp-gov-uk-website/icap-request-processing`

2. Download the newest version of Glasswall Rebuild SDK from https://github.com/filetrust/sdk-rebuild-eval

    * https://github.com/filetrust/sdk-rebuild-eval/raw/master/libs/rebuild/linux/libglasswall.classic.so
    * https://github.com/filetrust/sdk-rebuild-eval/raw/master/libs/rebuild/windows/glasswall.classic.dll

3. Place the file in respective folders

        libglasswall.classic.so -> lib/linux/SDK/
        glasswall.classic.dll   -> lib/windows/SDK/

4. Rebuild the Docker image with a new TAG and push to the repository

        docker build . -t elastisys/icap-request-processing:[TAG] --no-cache
        docker push elastisys/icap-request-processing:[TAG]

5. Update the tag in `wip-helmfile-glasswall-icap-adaptation.yaml.gotmpl` accordingly.
