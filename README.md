# gke-terra-ex

An example that demonstrates creating a gke cluster using terraform. The cluster includes the auto-scaling of nodes feature of gke. It also demonstrates most of the details required to actually use the cluster after stand up in that a Cloud DNS managed zone along with static IPs are created for the end applications. Associating the Kubernetes provider to the new cluster is demonstrated as well.  

The project uses a simple docker image from gcr.io called hello-app and shows pulling the image and pushing it to your project's container registry. The app is described here:

 https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/master/hello-app

### Files
  1. main.tf - terraform code
  1. terraform.tfvars - terraform vars file automatically pulled in
  1. hello-web.yaml - K8s deployment only
  1. hello-web-service.yaml - K8s service only
  1. hello-web-all.yaml - K8s deploy, service, and ingress combined

### Requirements
  1. gcloud sdk installed
  1. kubectl client installed
  1. An initial project created in GC

### Credentials
The code below shows how the google cloud credentials are loaded. Put your account.json file in an appropriate place, and reference the file.

```
provider "google" {
  credentials = "${file("~/.gcloud/account.json")}"
  ...
}
```

The linux passwords for access to the master node are also stored in a terraform variable file noted below.

```
// GKE master credentials
// In this file named gke-secrets.tfvars
linux_admin_username = "your-username"
linux_admin_password = "your-15-digit-pw"
```
### Building the cluster
The terraform.tfvars file contains the values for the google cloud region, project name, and min and max node parameters.
```
region = "us-central1-a"
project_name = "your-project-name"
min_nodes = "1"
max_nodes = "3"
```
Running the terraform plan and apply goes something like this:
```
terraform plan \
 -var-file="~/.gcloud/gke-secrets.tfvars"
```
### Associating kubectl to the Cluster Context
Use gcloud to make sure the config defaults are accurate, and get the cluster credentials.
```
gcloud config set project 'your-project-id'
gcloud config set compute/zone us-central1-a
gcloud container clusters get-credentials 'cluster-name'

```
### Associating the Kubernetes Provider
One neat trick demonstrated in this example is associating the Kubernetes provider direclty to the newly created GKE cluster. This allows you to immediately start configuring the new cluster via the kubernetes provider. The pertinent code is below:
```
provider "kubernetes" {
  host = "${google_container_cluster.primary.endpoint}"
  client_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
  client_key = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
}
```
The example uses the Kubernetes provider to immediately create standard namespaces for the cluster.
```
resource "kubernetes_namespace" "development" {
  metadata {
    name = "development"
  }
}
```
### Creating secrets
Say that some pods need to access a database. The username and password that the pods should use is in the files ./username.txt and ./password.txt on your local machine.

```
$ echo -n "admin" > ./username.txt
$ echo -n "1f2d1e2e67df" > ./password.txt
```
The kubectl create secret command packages these files into a Secret and creates the object on the Apiserver.

```
$ kubectl create secret generic db-user-pass \
  --from-file=./username.txt --from-file=./password.txt
secret "db-user-pass" created
```

Extraction of these secrets via environment variables is demonstrated in the companion kube-terra-ex project.
### DNS, Deployments, and Applications
This example now includes how to create a static IP for your containerized application as well as creating a Cloud DNS managed zone where ultimately the A-record for your application would be place. This is typically done with a Kubernetes 'Ingress' object, and this is demonstrated in the kube-terra-ex project. Below shows how the management of a global static IP address.
```
resource "google_compute_global_address" "hello-ip" {
  name = "first-cluster-hello-web-ip"
  ip_version = "IPV4"
}
```
### Init Containers
Because Init Containers have separate images from app Containers, they have some advantages for start-up related code:

  1. They can contain and run utilities that are not desirable to include in the app Container image for security reasons.
  1. They can contain utilities or custom code for setup that is not present in an app image. For example, there is no need to make an image FROM another image just to use a tool like sed, awk, python, or dig during setup.
  1. The application image builder and deployer roles can work independently without the need to jointly build a single app image.
  1. They use Linux namespaces so that they have different filesystem views from app Containers. Consequently, they can be given access to Secrets that app Containers are not able to access.
  1. They run to completion before any app Containers start, whereas app Containers run in parallel, so Init Containers provide an easy way to block or delay the startup of app Containers until some set of preconditions are met.

```
spec:
  containers:
  - name: myapp-container
    image: busybox
  initContainers:
  - name: init-myservice
    image: busybox
    command: ['sh', '-c', 'sleep 2; done;']
```
### Docker Build HelloNode
export your project id:
```
export PROJECT_ID="$(gcloud config get-value project -q)"
```
Build the docker image and push to your project's gcr:
```
docker build -t gcr.io/${PROJECT_ID}/hello-app:v1 .
gcloud docker -- push gcr.io/${PROJECT_ID}/hello-app:v1
```


### gcloud example commands
```
gcloud components install kubectl
gcloud config list
gcloud container clusters get-credentials [NAME]
```

### kubectl example commands
```
kubectl config view
kubectl cluster-info
kubectl describe pods
kubectl get pods --all-namespaces
kubectl get services
kubectl describe nodes
kubectl run hello-web --image=gcr.io/${PROJECT_ID}/hello-app:v1 \
    --port 8080
kubectl expose deployment hello-web \
  --type=LoadBalancer --port 80 \
  --target-port 8080
kubectl get deployment hello-web  
```
