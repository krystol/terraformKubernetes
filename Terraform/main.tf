locals {
  cluster_name = "terraform-cluster5"
  cluster_region = "us-east1"
  master_username = "1232"
}

locals {
  master_password = "masterpasswordmustbe16chars"
}


provider "google" {
  version = "~> 1.17"

  credentials = "${file("creds/service_account_key.json")}"
  project = "orbital-scene-220409"
  region  = "us-east1-b	"
}

provider "kubernetes" {
  host     = "https://${google_container_cluster.gke_cluster.endpoint}"
  username = "${var.master_username}"
  password = "${var.master_password}"

  client_certificate     = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)}"
}

resource "google_container_cluster" "gke_cluster" {
  name               = "terraform-cluster5"
  region             = "${var.gcp_region}"

  master_auth {
    username = "${var.master_username}"
    password = "${var.master_password}"
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }

  node_pool {
    name = "default-pool"
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = "terraform-cluster5-pool"
  region     = "${var.gcp_region}"
  cluster    = "${google_container_cluster.gke_cluster.name}"
  node_count = "${var.min_node_count}"

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "null_resource" "install_istio" {
  triggers {
    cluster_ep = "${google_container_cluster.gke_cluster.endpoint}"
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "${base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)}" > ca.crt;
      kubectl config --kubeconfig=ci set-cluster k8s --server=$${K8S_SERVER} --certificate-authority=ca.crt
      kubectl config --kubeconfig=ci set-credentials admin --username=$${K8S_USERNAME} --password=$${K8S_PASSWORD}
      kubectl config --kubeconfig=ci set-context k8s-ci --cluster=k8s --namespace=default --user=admin
      kubectl config --kubeconfig=ci use-context k8s-ci
      export KUBECONFIG=ci
      kubectl create serviceaccount --namespace kube-system tiller || true
      kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller || true
      helm init --upgrade --service-account tiller --wait
      helm repo add kubernetes-istio-module $${HELM_REPO}
      helm repo update
      kubectl create ns istio-system || true
      helm upgrade istio kubernetes-istio-module/istio --install --wait \
                --namespace istio-system \
		          --version $${ISTIO_VERSION}
      istioctl kube-inject -f mydeployment.yaml -o mydeployment-istio.yaml      
      kubectl create -f mydeployment-istio.yaml

EOT

	 

    environment {
      CA_CERTIFICATE = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)}"
      K8S_SERVER     = "https://${google_container_cluster.gke_cluster.endpoint}"
      K8S_USERNAME   = "${var.master_username}"
      K8S_PASSWORD   = "${var.master_password}"
      HELM_REPO      = "${var.helm_repository}"
      ISTIO_VERSION  = "${var.istio_version}"
    }
  }

  depends_on = ["google_container_node_pool.gke_node_pool"]
}
