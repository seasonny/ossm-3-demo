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

printf "${BYellow}Installing Bookinfo2...${NC}\n"
oc new-project istio-ingress2
printf "${BYellow}Adding istio-ingress2 namespace as a part of the mesh${NC}\n"
oc label namespace istio-ingress2 istio-injection=enabled
printf "${BYellow}Installing Istio Ingress Gateway for Bookinfo2...${NC}\n"
oc apply -f ./resources/OSSM3/istio-ingress2/istioIngressGateway2.yaml -n istio-ingress2
printf "${BYellow}Waiting for istio-ingressgateway2 pods to become ready...${NC}\n"
oc wait --for=condition=Ready pods --all -n istio-ingress2 --timeout 60s

# printf "${BYellow}Installing Hello Gateway...${NC}\n"
# oc apply -f ./resources/gateway/hello-gateway.yaml -n istio-ingress2
# printf "${BYellow}Waiting for hello-gateway pods to become ready...${NC}\n"
# oc wait --for=condition=Ready pods --all -l app=hello-gateway -n istio-ingress2 --timeout 60s

oc new-project bookinfo2
printf "${BYellow}Adding bookinfo2 namespace as a part of the mesh${NC}\n"
oc label namespace bookinfo2 istio-injection=enabled
printf "${BYellow}Enabling pod monitor in bookinfo2 namespac${NC}\n"
oc apply -f ./resources/Monitoring/podMonitor.yaml -n bookinfo2
printf "${BYellow}Installing Bookinfo2${NC}\n"
oc apply -f ./resources/Bookinfo/bookinfo.yaml -n bookinfo2
oc apply -f ./resources/Bookinfo/bookinfo2-gateway/bookinfo2-gateway.yaml -n bookinfo2
printf "${BYellow}Waiting for bookinfo2 pods to become ready...${NC}\n"
oc wait --for=condition=Ready pods --all -n bookinfo2 --timeout 60s

printf "${BYellow}Installation finished!${NC}\n"
printf "${BYellow}NOTE: Kiali will show metrics of bookinfo2 app right after pod monitor will be ready. You can check it in OCP console Observe->Metrics${NC}\n"

# this env will be used in traffic generator
export INGRESSHOST=$(oc get route istio-ingressgateway2 -n istio-ingress2 -o=jsonpath='{.spec.host}')
KIALI_HOST=$(oc get route kiali -n istio-system -o=jsonpath='{.spec.host}')

printf "${BYellow}[optional] Installing Bookinfo2 traffic generator...${NC}\n"
cat ./resources/Bookinfo/traffic-generator-configmap.yaml | ROUTE="http://${INGRESSHOST}/productpage" envsubst | oc -n bookinfo2 apply -f - 
oc apply -f ./resources/Bookinfo/traffic-generator.yaml -n bookinfo2

printf "${BYellow}====================================================================================================${NC}\n"
printf "Ingress route for bookinfo2 is: ${BBlue}http://${INGRESSHOST}/productpage${NC} (using istio-ingressgateway2 in istio-ingress2 namespace)\n"
printf "To test RestAPI: ${BBlue}sh ./scripts/test-api.sh${NC}\n"
printf "Kiali route is: ${BBlue}https://${KIALI_HOST}${NC}\n"
printf "${BYellow}====================================================================================================${NC}\n"
