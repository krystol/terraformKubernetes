#variable "gce_ssh_user" {}
provider "google" {
  version = "~> 1.17"
  credentials = "${file("creds/gft-microservices-activator.json")}"
  project = "${var.project_id}"
  region  = "${var.region}"
}


resource "google_compute_instance" "on_prem_host" {
  name         = "${var.onprem_name}"
  machine_type = "n1-standard-1"
  zone         = "${var.region}"


  metadata {
      sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<SCRIPT
echo "Script :: Turn off swap memory"
swapoff -a
echo "Script :: Turn off swap memory :: Done"

echo "Script :: Create repo to install kubernetes"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
echo "Script :: Create repo to install kubernetes :: Done"

echo "Script :: Set SELinux in permissive mode"
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo "Script :: Set SELinux in permissive mode :: Done"

echo "Script :: Instalation of k8s tools"
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet && systemctl start kubelet
echo "Script :: Instalation of k8s tools :: DONE"

echo "Script :: Instalation of Docker CE"
sudo yum install -y yum-utils \
device-mapper-persistent-data \
lvm2
sudo yum-config-manager --enable rhel-7-server-extras-rpms
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce
sudo systemctl start docker
sudo systemctl enable docker.service
echo "Script :: Instalation of Docker CE :: Done"

echo "Script :: Ensuring iptables not being bypassed"
cat <<EOF1 >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF1
cat <<EOF2 >  /etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF2
sudo sysctl -p
echo "Script :: Ensuring iptables not being bypassed :: Done"

echo "Script :: Kubeadm init"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
sudo yum -y update

echo "Script :: Install pod network"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
echo "Script :: Install pod network :: Done"

echo "Script :: Upload private key"
cat <<EOF3 >/home/knak/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAteebiEqDJr6yc1LwtwYibvESuTM8D168J7nqFD8iAgcULCox
2edeTy6VjWlpCy+pv72Fxz1Xhbh9bs3A/sPEDrEEk9JUlQGnha3yXNVZfmfvhrsV
nWtwcK9Ym5LXFCYH4ibtUcjXRYTcLnlRVaaLZLQSQf6IttTVmsfKB+OiWvwslgiA
Qs8Wiq7P1sC/xxVrxA3l93FyWU3CrsMGTFNIalKo0rkahed0axgh2OxUyrNXyPWh
QlthwGvEmziBdzPyeQZrWbO5stYlAB2Yi3mBqHIXekuSF7AXfWlILZxfbm8++FsO
IwrrZcdAl+cbwqQqPrCLqDUdEIOD685pJmrDFQIDAQABAoIBAQCF0fZMxKxJU58K
Uij+LEgmn7krf/KeSA5Zl18KOAu3vCdt+jikWp6518ZzuulpLk5N3YpOMeVyXXAB
lOJ3SeOw/y8j5GcPG6F3KamT++yTnrjKwFU9cu3MKGMiSFtr2jKQgBy0vvEHlp84
nU1lmlkP451O6YcAIgFmlbYeKaumDIKcAUq44xTiOe8pjifQNfFd9RanRL4mH07i
TH8qojMGMOsuBkeV0L1gMyzel6aII6i3pxvYuiJnw6uNRDgRS2Ri/t+xBUikhy4z
rSpTYAsR41o6V/lB8qaZ0Lk2ScuE3e0qVyKmyNYRxcJ3Ai4CaxhRk8E7vQtjfZjA
Bd5s9EIdAoGBAOF3mhUuLhkb5c5s/bdMSkE7d+ZL4NN96eRinvK2stqGKXwdwKi7
qrZ9VptLE/T9JOR3jMxC71ObHDeKK2a5QMBQ/WLIB21a6+53pouT4to6bNxYsfyz
4Hl75NmGPF2yNA7B89euSbU6xEdLMn96Y8YD6BOysoioucuHK6TOzBlfAoGBAM6J
zPycHo0lOCG0XiVAWaquGjQWGncdM8nQfYGqfKCWPYD3zVje6A+HlRkvRSZIh5y7
iW0SCcq7weUxdpeHjeMeTnBsZK0vHDjNFM3PUpHcoZ/WhiWHg68/5RCLGbeQm+vs
EJV22B0InErOTDRQUQdHTD4AEH5INfmA6DStPdQLAoGAUnGFahFE0fGdimnYLFo9
HLU+FnvQbgUwrU5SiLW9mKJOMRBADnLw7WHPdWFynrah8ti0J0yibpPdMYHYdOtw
feIfhStXa+k/NCeUQp2E6f9LJxdXneu4PTPMbq3jDO/IkUzieQ9F7HrcoqUghfSe
3x02k11YYxgvN/jpQI5Nm0kCgYBKvlm9jS4NPEvs/p4XcwtAFlOLR/h55MqKHXZe
B3mkj9pgIs1gfQKUJCfT/mRS72qMUN3x59Y9VOddbyIQwlCZwaz3SHLCrcrTz3vY
409pU+P1uSfAyyLfuArIit5arO2QWlTCEkkxcJ1HARNY1zwLm0S/JzzQxocp7Pmb
nppCcwKBgQDcaXFe0euzMXKfS9v0C9plhlhqiY7aM+4g/ACl54vH3Jh6daHvOYmu
ctzqvRqnfLJm92aeTyCJI6F1g9z+Yfagji4PnKMVYbjBgp8gfQMe7+wuuL8N6PWz
1+RWVwVp/2JMPyfXMmMCpnPCMB9LNw7BTHWrL5q27MFjBRXDcXJyIA==
-----END RSA PRIVATE KEY-----
EOF3
echo "Script :: Upload private key :: Done"

echo "Script :: Set settings for private key"
sudo chmod 600 /home/knak/.ssh/id_rsa
sudo chmod 700 /home/knak/.ssh
sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config
echo "Script :: Set settings for private key :: Done"

SCRIPT

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_instance" "on_prem_node" {
  name         = "${var.onprem_name_node}"
  machine_type = "n1-standard-2"
  zone         = "${var.region}"


  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
      sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = <<SCRIPT
echo "Script :: Turn off swap memory"
swapoff -a
echo "Script :: Turn off swap memory :: Done"

echo "Script :: Create repo to install kubernetes"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
echo "Script :: Create repo to install kubernetes :: Done"

echo "Script :: Set SELinux in permissive mode"
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo "Script :: Set SELinux in permissive mode :: Done"

echo "Script :: Instalation of k8s tools"
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet && systemctl start kubelet
echo "Script :: Instalation of k8s tools :: DONE"

echo "Script :: Ensuring iptables not being bypassed"
cat <<EOF1 >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF1
sysctl --system
cat <<EOF2 >  /etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF2
sysctl -p
echo "Script :: Ensuring iptables not being bypassed :: Done"

echo "Script :: Instalation of Docker CE"
sudo yum install -y yum-utils \
device-mapper-persistent-data \
lvm2
sudo yum-config-manager --enable rhel-7-server-extras-rpms
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce
sudo systemctl start docker
sudo systemctl enable docker.service
echo "Script :: Instalation of Docker CE :: Done"

echo "Script :: Kubeadm init"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 >> out.txt
sudo yum -y update
SCRIPT

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}