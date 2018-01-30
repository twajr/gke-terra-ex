# gke-terra-ex

An example that demonstrates creating a gke cluster using terraform. The cluster includes the auto-scaling of nodes feature of gke.

### Credentials
The code below shows how the google cloud credentials are loaded. Put your account.json file in an appropriate place, and reference the file.

```
provider "google" {
  credentials = "${file("~/.gcloud/account.json")}"
  ...
}```

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
 -var-file="terraform.tfvars" \
 -var-file="~/.gcloud/gke-secrets.tfvars"
```
