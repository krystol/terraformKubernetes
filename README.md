**Create the docker images and add them to the registry**

docker build -t gcr.io/proj-name/account-microservice:v9 .
docker build -t gcr.io/proj-name/trading-microservice:v1 .
docker build -t gcr.io/proj-name/trading-microservice:v2 .


gcloud docker -- push gcr.io/proj-name/account-microservice:v9
gcloud docker -- push gcr.io/proj-name/trading-microservice:v1
gcloud docker -- push gcr.io/proj-name/trading-microservice:v2


**Inject envoy sidecar proxies alongside each service to provide Istio functionality.**
istioctl kube-inject -f helloworld.yaml -o helloworld-istio.yaml

**Create the deployment using the updated yaml file**
kubectl create -f helloworld-istio.yaml