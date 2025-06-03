#!/bin/bash

echo "Starting egress gateway test script..."

# 1. Ask for the namespace
read -p "Please enter the namespace for testing: (e.g., curl) " NAMESPACE
echo "Using namespace: $NAMESPACE"

# 2. Apply curl.yaml
echo "Applying curl.yaml to '$NAMESPACE' namespace..."
oc apply -n "$NAMESPACE" -f resources/tools/curl.yaml

# 2. Get CURL_POD name
echo "Getting CURL_POD name..."
export CURL_POD=$(oc get pod -n "$NAMESPACE" -l app=curl -o jsonpath='{.items[0].metadata.name}')
echo "CURL_POD: $CURL_POD"
oc rollout status deployment/curl -n "$NAMESPACE"

# 3. Execute curl command from CURL_POD
echo "Executing curl from CURL_POD to http://redhat.com..."
oc exec "$CURL_POD" -n "$NAMESPACE" -c curl -- curl -sSL -o /dev/null -D - http://redhat.com

# 4. Get logs from istio-egressgateway deployment
echo "Fetching last 5 logs from istio-egressgateway deployment..."
oc logs deployment/istio-egressgateway -n "$NAMESPACE" | tail -5 | grep redhat.com

echo "Run the following command to see the full logs of the istio-egressgateway deployment:"
echo "oc logs deployment/istio-egressgateway -n "$NAMESPACE""

echo "Egress gateway test script completed."
