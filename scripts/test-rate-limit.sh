#!/bin/bash

echo "Testing rate limiting on the Bookinfo application..."
export GATEWAY_URL=$(oc -n istio-ingress get route istio-ingressgateway -o jsonpath='{.spec.host}')
for i in {1..20}; do curl -s "http://$GATEWAY_URL/productpage" -o /dev/null -w "%{http_code}\n"; done

echo "Testing rate limiting on the Reviews service...(internal traffic)"
oc exec "$(oc get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- bash -c 'for i in {1..20}; do curl -s productpage:9080/productpage -o /dev/null -w "%{http_code}\n"; done'