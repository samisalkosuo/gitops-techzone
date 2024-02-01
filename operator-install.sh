#!/bin/bash

#helper tool to install operators to OpenShift cluster
#purpose is to have single script that can be reused to install
#operators to specific namespaces

#see YAMLs below and change version etc. as necessary

function help
{
    echo "Operator Install Tool."
    echo ""
    echo "Usage: $0 <operator> [<namespace>]"
    echo ""
    echo "Commands/Operators:"
    echo ""
    echo "  init                     - Install required operators (see script source)."
    echo "  ibm-catalog-source       - Install IBM Catalog source."
    echo "  cert-manager             - Install Certificate Manager (Community) operator."
    echo "  ibm-licensing            - Install IBM Licensing operator."
    echo "  ibm-process-mining <ns>  - Install IBM Process Mining operator to given namespace."
    
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


function installCertManagerOperator {

    cat > file.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cert-manager
  namespace: openshift-operators
  annotations:
    argocd.argoproj.io/sync-wave: "-7"
spec:
  channel: stable
  installPlanApproval: Automatic
  name: cert-manager
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
  oc apply -f file.yaml

}

function installIBMLicensingOperator
{
    local NAMESPACE=ibm-licensing
    cat > file.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  annotations:
    argocd.argoproj.io/sync-wave: "-10"
spec:
  finalizers:
  - kubernetes
EOF
    oc apply -f file.yaml

    cat > file.yaml << EOF
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: ibm-licensing-group
  namespace: ${NAMESPACE}
  annotations:
    argocd.argoproj.io/sync-wave: "-8"
spec:
  targetNamespaces:
  - ${NAMESPACE}
EOF
    oc apply -f file.yaml

    cat > file.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-licensing-operator-app
  namespace: ${NAMESPACE}
  annotations:
    argocd.argoproj.io/sync-wave: "-7"
spec:
  channel: v4.2
  installPlanApproval: Automatic
  name: ibm-licensing-operator-app
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
    oc apply -f file.yaml
    
}

function installIBMCatalogSource {

    cat > file.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
  annotations:
    argocd.argoproj.io/sync-wave: "-100"
spec:
 displayName: IBM Operator Catalog
 publisher: IBM
 sourceType: grpc
 image: icr.io/cpopen/ibm-operator-catalog
 updateStrategy:
  registryPoll:
   interval: 45m
EOF
    oc apply -f file.yaml
}

function installIBMProcessMiningOperator
{
    local NAMESPACE=$1
    cat > file.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  annotations:
    argocd.argoproj.io/sync-wave: "-10"
spec:
  finalizers:
  - kubernetes
EOF
    oc apply -f file.yaml

    cat > file.yaml << EOF
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: processmining-group
  namespace: ${NAMESPACE}
  annotations:
    argocd.argoproj.io/sync-wave: "-8"
spec:
  targetNamespaces:
  - ${NAMESPACE}
EOF
    oc apply -f file.yaml

    cat > file.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-automation-processmining
  namespace: ${NAMESPACE}
  annotations:
    argocd.argoproj.io/sync-wave: "-7"
spec:
  channel: v3.0
  installPlanApproval: Automatic
  name: ibm-automation-processmining
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
    oc apply -f file.yaml

}

case "$1" in
    help)
        help
    ;;
    init)
        installIBMCatalogSource
        installCertManagerOperator
        installIBMLicensingOperator
    ;;
    ibm-catalog-source)
        installIBMCatalogSource
    ;;
    cert-manager)
        installCertManagerOperator
    ;;
    ibm-licensing)
        installIBMLicensingOperator
    ;;
    ibm-process-mining)
        shift
        if [[ "$1" == "" ]]; then
            error "Namespace is missing."
            exit 1
        fi
        installIBMProcessMiningOperator $1
    ;;
    *)
        help
    ;;
esac

