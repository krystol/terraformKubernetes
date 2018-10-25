Steps






1. Add service account key in creds/service_account_key.json
2. Install git, terraform, helm, gcloud and kubectl wherever the terraform plan is being run from
3. Initialise and apply terraform plan


Installing git 
```
sudo apt-get update
sudo apt-get install git
```

Installing terraform 
```
sudo apt-get install unzip
wget https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip
unzip terraform_0.11.8_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

Installing helm
```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```

Installing gcloud
```
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-222.0.0-linux-x86_64.tar.gz
tar zxvf [file] google-cloud-sdk
gcloud init
```

Installing kubectl
```
sudo apt-get install -y kubectl
```

Initialise and apply the terraform plan
```
terraform init
terraform apply
```





