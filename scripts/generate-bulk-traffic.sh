#!/bin/bash

export GATEWAY_URL=$(oc -n istio-ingress get route istio-ingressgateway -o jsonpath='{.spec.host}')

for i in {1..20}; do
  echo -n "請求 #$i: "
  status_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$GATEWAY_URL/productpage")
  echo "HTTP 狀態碼: $status_code"
done