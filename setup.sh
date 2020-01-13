#!/usr/bin/env bash

echo Genreating SSH keys
mkdir .ssh
rm -f .ssh/id_rsa*
rm -f .ssh/known_hosts
set -e

ssh-keygen -f .ssh/id_rsa

az group create --location francecentral --name $GROUP_NAME

vms=( ansible zk1 zk2 zk3 b1 b2 b3 ccc )

echo Creating infrastructure
for vm in "${vms[@]}"
do
    az vm create --image debian --resource-group $GROUP_NAME \
     --name $vm --admin-username confluent
done

echo Importing VM fingerprints for ssh

az vm list-ip-addresses --resource-group $GROUP_NAME \
    |jq --raw-output \ '.[] | .virtualMachine.network.publicIpAddresses[] | "ssh-keyscan -H " + .ipAddress + " >> ~/.ssh/known_hosts" ' | sh


ansible_ip=$(az vm list-ip-addresses --resource-group $GROUP_NAME --name ansible|jq --raw-output '.[] | .virtualMachine.network.publicIpAddresses[] | .ipAddress ')

ssh confluent@$ansible_ip -t 'sudo apt-get update && sudo apt-get install -y git ansible gpg'

ssh confluent@$ansible_ip -t 'git clone https://github.com/confluentinc/cp-ansible'

scp hosts.yml confluent@$ansible_ip:~/cp-ansible/hosts.yml

scp ~/.ssh/id_rsa* confluent@$ansible_ip:~/.ssh/


for vm in "${vms[@]}"
do
    ssh confluent@$ansible_ip -t "ssh-keyscan -H $vm >> ~/.ssh/known_hosts"
    ssh confluent@$ansible_ip -t "ssh -t $vm 'sudo apt-get install -y gpg'"
done

ssh -t confluent@$ansible_ip "cd cp-ansible; ansible -i hosts.yml all -m ping && ansible-playbook -i hosts.yml all.yml"


