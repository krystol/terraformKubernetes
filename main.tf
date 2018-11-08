provider "google" {
  version = "~> 1.17"
  credentials = "${file("creds/service_account_key.json")}"
  project = "${var.project_id}"
  region  = "${var.region}"
}

resource "google_container_cluster" "gke_cluster" {
  name               = "${var.cluster_name}"
  region             = "${var.region}"

  node_pool {
    name = "default-pool"
  }

    master_auth {
    username = "${var.username}"
    password = "${var.password}"
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = "first-pool"
  region     = "${var.region}"
  cluster    = "${google_container_cluster.gke_cluster.name}"
  node_count = "4"
}

resource "google_compute_instance" "default" {
  name         = "${var.bastion_name}"
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    foo = "bar"
  }

  metadata_startup_script = <<SCRIPT
		  # update debian and install kubectl
		sudo apt-get install -y sudo git google-cloud-sdk curl kubectl 
    # get and unpack istio
		wget https://github.com/istio/istio/releases/download/1.0.3/istio-1.0.3-linux.tar.gz
		    
		tar xzf istio-1.0.3-linux.tar.gz 
    # change to the istio directory and edit PATH to add istioctl
		cd istio-1.0.3
		export PATH=$PWD/bin:$PATH 
    # authenticate to the kubernetes cluster
	echo "${base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)}" > ca.crt 
    kubectl config --kubeconfig=ci set-cluster k8s --server="https://${google_container_cluster.gke_cluster.endpoint}" --certificate-authority=ca.crt
    kubectl config --kubeconfig=ci set-credentials admin --username="${var.username}" --password="${var.password}" 
    kubectl config --kubeconfig=ci set-context k8s-ci --cluster=k8s --namespace=default --user=admin
    kubectl config --kubeconfig=ci use-context k8s-ci
    export KUBECONFIG=ci 
    # install istio
		kubectl apply -f install/kubernetes/istio-demo-auth.yaml &>> /output.txt

	SCRIPT

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

   depends_on = ["google_container_node_pool.gke_node_pool"]
}
