#!/usr/bin/env bash
#Create multiple Jmeter namespaces on an existing kuberntes cluster
#Started On January 23, 2018

set -x

working_dir=`pwd`

echo "checking if kubectl is present"

if ! hash kubectl 2>/dev/null
then
    echo "'kubectl' was not found in PATH"
    echo "Kindly ensure that you can acces an existing kubernetes cluster via kubectl"
    exit
fi

kubectl version --short

echo "Current list of namespaces on the kubernetes cluster:"


gcloud beta container --project "momo-develop" clusters create "standard-cluster-1" --zone "asia-east1-a" --no-enable-basic-auth --cluster-version "1.13.7-gke.8" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --no-enable-cloud-logging --no-enable-cloud-monitoring --enable-private-nodes --master-ipv4-cidr "172.16.0.0/28" --enable-ip-alias --network "projects/momo-develop/global/networks/gke-network" --subnetwork "projects/momo-develop/regions/asia-east1/subnetworks/subnet-192" --default-max-pods-per-node "110" --enable-master-authorized-networks --master-authorized-networks 0.0.0.0/0 --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair


tenant=momotest




kubectl create namespace $tenant

echo "Namspace $tenant has been created"

echo

echo "Creating Jmeter slave nodes"

nodes=`kubectl get no | egrep -v "master|NAME" | wc -l`

echo

echo "Number of worker nodes on this cluster is " $nodes

echo

#echo "Creating $nodes Jmeter slave replicas and service"

echo

kubectl create -n $tenant -f $working_dir/jmeter_slaves_deploy.yaml

kubectl create -n $tenant -f $working_dir/jmeter_slaves_svc.yaml

echo "Creating Jmeter Master"

kubectl create -n $tenant -f $working_dir/jmeter_master_configmap.yaml

kubectl create -n $tenant -f $working_dir/jmeter_master_deploy.yaml


echo "Creating Influxdb and the service"

kubectl create -n $tenant -f $working_dir/jmeter_influxdb_configmap.yaml

kubectl create -n $tenant -f $working_dir/jmeter_influxdb_deploy.yaml

kubectl create -n $tenant -f $working_dir/jmeter_influxdb_svc.yaml

echo "Creating Grafana Deployment"

kubectl create -n $tenant -f $working_dir/jmeter_grafana_deploy.yaml

kubectl create -n $tenant -f $working_dir/jmeter_grafana_svc.yaml

echo "Printout Of the $tenant Objects"

echo

kubectl get -n $tenant all

echo namespace = $tenant > $working_dir/tenant_export
