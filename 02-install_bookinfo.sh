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

printf "${BYellow}Installing Bookinfo...${NC}\n"
oc new-project bookinfo
printf "${BYellow}Adding bookinfo namespace as a part of the mesh${NC}\n"
oc label namespace bookinfo istio-injection=enabled
printf "${BYellow}Enabling pod monitor in bookinfo namespac${NC}\n"
oc apply -f ./resources/Monitoring/podMonitor.yaml -n bookinfo
printf "${BYellow}Installing Bookinfo${NC}\n"
oc apply -f ./resources/Bookinfo/bookinfo.yaml -n bookinfo
oc apply -f ./resources/Bookinfo/bookinfo-gateway.yaml -n bookinfo
printf "${BYellow}Waiting for bookinfo pods to become ready...${NC}\n"
oc wait --for=condition=Ready pods --all -n bookinfo --timeout 60s

printf "${BYellow}Installation finished!${NC}\n"
printf "${BYellow}NOTE: Kiali will show metrics of bookinfo app right after pod monitor will be ready. You can check it in OCP console Observe->Metrics${NC}\n"

# this env will be used in traffic generator
export INGRESSHOST=$(oc get route istio-ingressgateway -n istio-ingress -o=jsonpath='{.spec.host}')
KIALI_HOST=$(oc get route kiali -n istio-system -o=jsonpath='{.spec.host}')

printf "${BYellow}[optional] Installing Bookinfo traffic generator...${NC}\n"
cat ./resources/Bookinfo/traffic-generator-configmap.yaml | ROUTE="http://${INGRESSHOST}/productpage" envsubst | oc -n bookinfo apply -f - 
oc apply -f ./resources/Bookinfo/traffic-generator.yaml -n bookinfo

printf "${BYellow}====================================================================================================${NC}\n"
printf "Ingress route for bookinfo is: ${BBlue}http://${INGRESSHOST}/productpage${NC}\n"
printf "To test RestAPI: ${BBlue}sh ./scripts/test-api.sh${NC}\n"
printf "Kiali route is: ${BBlue}https://${KIALI_HOST}${NC}\n"
echo "${BYellow}====================================================================================================${NC}"
