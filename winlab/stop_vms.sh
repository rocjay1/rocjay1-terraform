#!/bin/bash

RG="rg-winlab-o8mr"

for VM in DC01 DC02 Server01 Server02 Storage01 Client01; do
    echo "Stopping $VM..."
    az vm deallocate --resource-group $RG --name $VM
    echo "...Finished stopping $VM!"
done
