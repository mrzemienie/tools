#!/bin/bash

#############################
# Run this tool to find services exposed via the GKE ingress controller
# across all projects in your organization
# Enjoy!
#############################

if [ -z "$1" ]; then
  if [ -z "$IGNORE" ]; then
    target=$(gcloud projects list --format="get(projectId)")
  else
    target=$(gcloud projects list --format="get(projectId)" | egrep -v "$IGNORE")
  fi
else
  target="$1"
fi

for proj in $target; do
  echo "[*] scraping project $proj"

  enabled=$(gcloud services list --project "$proj" | grep "Kubernetes Engine API")

  if [ -z "$enabled" ]; then
    continue
  fi


  IFS=$'\n'
  for cluster in $(gcloud container clusters list --quiet --project $proj --format="get(name,location)"); do
    name=$(echo "$cluster" | awk '{print $1}')
    zone=$(echo "$cluster" | awk '{print $2}')

    echo "[*] Authenticating to cluster $name in project $proj"
    gcloud container clusters get-credentials "$name" --zone "$zone" --project "$proj"
    if [ $? -eq 0 ]; then
        :
    else
      echo "[!] Could not grab kubectl creds, skipping"
      continue
    fi

    # Timeout the commands as firewall may not permit inbound cluster querying
    # Also, the json output will return text even if no ingresses configured,
    # so we want to make sure the unformatted output contains something before
    # writing unnecessary files
    ingress=$(timeout 15s kubectl get ingress --all-namespaces)
    if [ -z "$ingress" ]; then
      continue
    fi

    mkdir -p k8s-data/"$proj"
    kubectl get ingress --all-namespaces -o json > "k8s-data/$proj/$name.json"
    echo "$ingress" > "k8s-data/$proj/$name.txt"

  done
done
