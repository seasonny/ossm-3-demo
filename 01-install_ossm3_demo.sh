#!/bin/bash

NC='\033[0m'          # Text Reset
BGreen='\033[1;32m'   # Green
BYellow='\033[1;33m'  # Yellow
#BBlack='\033[1;30m'  # Black
#BRed='\033[1;31m'    # Red
BBlue='\033[1;34m'    # Blue
#BPurple='\033[1;35m' # Purple
#BCyan='\033[1;36m'   # Cyan
#BWhite='\033[1;37m'  # White

printf "${BGreen}This script set up the whole OSSM3 demo.${NC}\n"

printf "${BYellow}Installing Minio for Tempo${NC}\n"
oc new-project tracing-system
oc apply -f ./resources/TempoOtel/minio.yaml -n tracing-system
printf "${BYellow}Waiting for Minio to become available...${NC}\n"
oc wait --for condition=Available deployment/minio --timeout 150s -n tracing-system

printf "${BYellow}Installing TempoCR${NC}\n"
oc apply -f ./resources/TempoOtel/tempo.yaml -n tracing-system
printf "${BYellow}Waiting for TempoStack to become ready...${NC}\n"
oc wait --for condition=Ready TempoStack/sample --timeout 150s -n tracing-system
printf "${BYellow}Waiting for Tempo deployment to become available...${NC}\n"
oc wait --for condition=Available deployment/tempo-sample-compactor --timeout 150s -n tracing-system

printf "${BYellow}Exposing Jaeger UI route (will be used in kiali ui)${NC}\n"
oc expose svc tempo-sample-query-frontend --port=jaeger-ui --name=tracing-ui -n tracing-system

printf "${BYellow}Installing OpenTelemetryCollector...${NC}\n"
oc new-project opentelemetrycollector
oc apply -f ./resources/TempoOtel/opentelemetrycollector.yaml -n opentelemetrycollector
printf "${BYellow}Waiting for OpenTelemetryCollector deployment to become available...${NC}\n"
oc wait --for condition=Available deployment/otel-collector --timeout 60s -n opentelemetrycollector

printf "${BYellow}Installing OSSM3...${NC}\n"
oc new-project istio-system
printf "${BYellow}Installing IstioCR...${NC}\n"
oc apply -f ./resources/OSSM3/istiocr.yaml  -n istio-system
printf "${BYellow}Waiting for istio to become ready...${NC}\n"
oc wait --for condition=Ready istio/default --timeout 60s  -n istio-system

printf "${BYellow}Installing Telemetry resource...${NC}\n"
oc apply -f ./resources/TempoOtel/istioTelemetry.yaml  -n istio-system
printf "${BYellow}Adding OTEL namespace as a part of the mesh${NC}\n"
oc label namespace opentelemetrycollector istio-injection=enabled

printf "${BYellow}Installing IstioCNI...${NC}\n"
oc new-project istio-cni
oc apply -f ./resources/OSSM3/istioCni.yaml -n istio-cni
printf "${BYellow}Waiting for istiocni to become ready...${NC}\n"
oc wait --for condition=Ready istiocni/default --timeout 60s -n istio-cni

printf "${BYellow}Creating ingress gateway via Gateway API...${NC}\n"
oc new-project istio-ingress
printf "${BYellow}Adding istio-ingress namespace as a part of the mesh${NC}\n"
oc label namespace istio-ingress istio-injection=enabled
oc apply -k ./resources/gateway

printf "${BYellow}Creating ingress gateway via Istio Deployment...${NC}\n"
#oc new-project istio-ingress
#echo "Adding istio-ingress namespace as a part of the mesh"
#oc label namespace istio-ingress istio-injection=enabled
oc apply -f ./resources/OSSM3/istioIngressGateway.yaml  -n istio-ingress
printf "${BYellow}Waiting for deployment/istio-ingressgateway to become available...${NC}\n"
oc wait --for condition=Available deployment/istio-ingressgateway --timeout 60s -n istio-ingress
printf "${BYellow}Exposing Istio ingress route${NC}\n"
oc expose svc istio-ingressgateway --port=http2 --name=istio-ingressgateway -n istio-ingress

printf "${BYellow}Enabling user workload monitoring in OCP${NC}\n"
oc apply -f ./resources/Monitoring/ocpUserMonitoring.yaml
printf "${BYellow}Enabling service monitor in istio-system namespace${NC}\n"
oc apply -f ./resources/Monitoring/serviceMonitor.yaml -n istio-system
printf "${BYellow}Enabling pod monitor in istio-system namespace${NC}\n"
oc apply -f ./resources/Monitoring/podMonitor.yaml -n istio-system
printf "${BYellow}Enabling pod monitor in istio-ingress namespace${NC}\n"
oc apply -f ./resources/Monitoring/podMonitor.yaml -n istio-ingress

printf "${BYellow}Installing Kiali...${NC}\n"
oc project istio-system
printf "${BYellow}Creating cluster role binding for kiali to read ocp monitoring${NC}\n"
oc apply -f ./resources/Kiali/kialiCrb.yaml -n istio-system
printf "${BYellow}Installing KialiCR...${NC}\n"
export TRACING_INGRESS_ROUTE="http://$(oc get -n tracing-system route tracing-ui -o jsonpath='{.spec.host}')"
cat ./resources/Kiali/kialiCr.yaml | JAEGERROUTE="${TRACING_INGRESS_ROUTE}" envsubst | oc -n istio-system apply -f - 
printf "${BYellow}Waiting for kiali to become ready...${NC}\n"
oc wait --for condition=Successful kiali/kiali --timeout 150s -n istio-system 
oc annotate route kiali haproxy.router.openshift.io/timeout=60s -n istio-system 

printf "${BYellow}Install Kiali OSSM Console plugin...${NC}\n"
oc apply -f ./resources/Kiali/kialiOssmcCr.yaml -n istio-system

printf "${BYellow}Installing Sample RestAPI...${NC}\n"
oc apply -k ./resources/application/kustomize/overlays/pod
