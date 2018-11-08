provider "google" {
  version = "~> 1.17"
  credentials = "${file("creds/service_account_key_GFT.json")}"
  project = "gft-microservices-activator"
  region  = "us-east1-b	"
}

resource "google_container_cluster" "gke_cluster" {
  name               = "terraform-cluster"
  region             = "us-east1-b"

  node_pool {
    name = "default-pool"
  }

    master_auth {
    username = "usernameformasterauth"
    password = "passwordmustbe16characters"
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = "first-pool"
  region     = "us-east1-b"
  cluster    = "${google_container_cluster.gke_cluster.name}"
  node_count = "4"
}

resource "google_compute_instance" "default" {
  name         = "thomas-bastion-vm"
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
		wget https://github.com/istio/istio/releases/download/1.0.2/istio-1.0.2-linux.tar.gz 
		tar xzf istio-1.0.2-linux.tar.gz 

    # change to the istio directory and edit PATH to add istioctl
		cd istio-1.0.2 
		export PATH=$PWD/bin:$PATH 

    # authenticate to the kubernetes cluster
	echo "${base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)}" > ca.crt 
    kubectl config --kubeconfig=ci set-cluster k8s --server="https://${google_container_cluster.gke_cluster.endpoint}" --certificate-authority=ca.crt
    kubectl config --kubeconfig=ci set-credentials admin --username="usernameformasterauth" --password="passwordmustbe16characters" 
    kubectl config --kubeconfig=ci set-context k8s-ci --cluster=k8s --namespace=default --user=admin
    kubectl config --kubeconfig=ci use-context k8s-ci
    export KUBECONFIG=ci 

    # install istio
		kubectl apply -f install/kubernetes/istio-demo-auth.yaml &>> /output.txt
		
		kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 & &>> /output.txt
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 & &>> /output.txt
kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 & &>> /output.txt
	SCRIPT

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

   depends_on = ["google_container_node_pool.gke_node_pool"]
}