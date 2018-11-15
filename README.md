
# Applying The Terraform Plan
1. Create a service account in GCP, download the JSON key, and save it to creds/service_account_key.json

2. Install terraform locally
3. Run the following commands
    * terraform init
    * terraform apply
    * when prompted for confirmation to apply the plan - enter 'yes'
    
(This should take 3-10 mins)

# Deployment

* istio-1.0.3/bin/istioctl kube-inject -f deployment.yaml -o deployment-istio.yaml
* kubectl create -f deployment-istio.yaml

##### Applying Destination Rule
* kubectl apply -f destination-rule.yaml

##### Applying Virtualservices For Routing
* kubectl apply -f all-traffic-to-v1.yaml
* kubectl apply -f weighted-routing-90-10.yaml
* kubectl apply -f route-by-header.yaml

