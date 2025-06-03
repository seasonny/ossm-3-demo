#!/bin/bash

# Define the namespace
read -p "Enter the namespace to install Istio Egress Gateway components (e.g., curl): " NAMESPACE

echo "Creating namespace: $NAMESPACE"
export NAMESPACE=${NAMESPACE}
oc new-project ${NAMESPACE}

echo "Installing Istio Egress Gateway components in namespace: $NAMESPACE"
# Apply istioEgressGateway.yaml
echo "Applying resources/egressGateway/istioEgressGateway.yaml with NAMESPACE=$NAMESPACE..."
envsubst < resources/egressGateway/istioEgressGateway.yaml | oc apply -n ${NAMESPACE} -f -

# Apply egress-traffic-config.yaml with variable replacement
echo "Applying resources/egressGateway/egress-traffic-config.yaml with NAMESPACE=$NAMESPACE..."
envsubst < resources/egressGateway/egress-traffic-config.yaml | oc apply -n ${NAMESPACE} -f -

# Label the namespace for Istio injection
echo "Labeling namespace ${NAMESPACE} for Istio injection..."
oc label namespace ${NAMESPACE} istio-injection=enabled
oc label namespace ${NAMESPACE} istio.io/rev=default

oc rollout status deployment/istio-egressgateway -n ${NAMESPACE}

echo "Egress Gateway installation script completed."
