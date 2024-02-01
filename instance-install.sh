#!/bin/bash

#helper tool to install various instances to OpenShift cluster
#purpose is to have single script that can be reused to install
#instances to specific namespaces

#see YAMLs below and change version etc. as necessary

function help
{
    echo "Instance Install Tool."
    echo ""
    echo "Usage: $0 <command> [<namespace>]"
    echo ""
    echo "Commands:"
    echo ""
    echo "  ibm-process-mining <ns>  - Install IBM Process Mining instance to given namespace."
    
    echo ""
    exit 1
}

function error
{
    echo "ERROR: $1"
    exit 1
}

if [[ "$1" == "" ]]; then
    #echo "No commands."
    help
fi


function installIBMProcessMiningInstance 
{
  local NAMESPACE=$1
  cat > file.yaml << EOF
apiVersion: processmining.ibm.com/v1beta1
kind: ProcessMining
metadata:
  name: pm
  namespace: ${NAMESPACE}
spec:
  cloudpak:
    zen:
      create: true
  defaultStorageClassName: ocs-storagecluster-cephfs
  license:
    accept: true
    cloudPak: IBM Cloud Pak for Business Automation
  loglevel: INFO
  processmining:
    storage:
      redis:
        install: false
  taskmining:
    install: false
  version: 1.14.3
EOF
  oc apply -f file.yaml

}

case "$1" in
    help)
        help
    ;;
    ibm-process-mining)
        shift
        if [[ "$1" == "" ]]; then
            error "Namespace is missing."
            exit 1
        fi
        installIBMProcessMiningInstance $1
    ;;
    *)
        help
    ;;
esac

