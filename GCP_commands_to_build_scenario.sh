## Define variables
PROJECT=cedar-card-200213

## Create bucket and populate it with startup script
gsutil mb gs://project-ops
gsutil cp startup-script.sh gs://project-ops/mongo/startup-script.sh


## Create GCP VPC Network and Subnet
gcloud compute --project=$PROJECT networks create network-mongo --subnet-mode=custom
gcloud compute --project=$PROJECT networks subnets create subnet-mongo --network=network-mongo --region=europe-west2 --range=192.168.80.0/24

## Create GCP Firewall Rules
gcloud compute --project=$PROJECT firewall-rules create mongo-allow-ports --direction=INGRESS --priority=1000 --network=network-mongo --action=ALLOW --rules=tcp:22,tcp:27017-27019,icmp --source-ranges=0.0.0.0/0 --target-tags=mongo
gcloud compute --project=$PROJECT firewall-rules create mongo-allow-ports-egress --direction=EGRESS --priority=1000 --network=network-mongo --action=ALLOW --rules=all --destination-ranges=0.0.0.0/0 --target-tags=mongo

## Create GCP Compute Instances
gcloud beta compute --project=$PROJECT instances create mongo-0 --machine-type=f1-micro --subnet=subnet-mongo --tags=mongo --image-family=ubuntu-1404-lts --image-project=ubuntu-os-cloud --metadata startup-script-url=gs://project-ops/mongo/startup-script.sh,hostname=mongodb0.example.net
gcloud beta compute --project=$PROJECT instances create mongo-1 --machine-type=f1-micro --subnet=subnet-mongo --tags=mongo --image-family=ubuntu-1404-lts --image-project=ubuntu-os-cloud --metadata startup-script-url=gs://project-ops/mongo/startup-script.sh,hostname=mongodb1.example.net
gcloud beta compute --project=$PROJECT instances create mongo-2 --machine-type=f1-micro --subnet=subnet-mongo --tags=mongo --image-family=ubuntu-1404-lts --image-project=ubuntu-os-cloud --metadata startup-script-url=gs://project-ops/mongo/startup-script.sh,hostname=mongodb2.example.net

## Delete setup in this order
gcloud beta compute --project=$PROJECT instances delete mongo-1 --quiet
gcloud compute --project=$PROJECT firewall-rules delete mongo-allow-ports
gcloud compute --project=$PROJECT firewall-rules delete mongo-allow-ports-egress
gcloud compute --project=$PROJECT networks subnets delete subnet-mongo
gcloud compute --project=$PROJECT networks delete network-mongo
gsutil rb -f gs://project-ops
