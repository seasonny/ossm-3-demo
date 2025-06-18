#!/bin/bash

# Define the namespace where Bookinfo is deployed
NAMESPACE="bookinfo" # Assuming Bookinfo is in 'bookinfo' namespace, adjust if different

# Define the path to the traffic management YAML files
TRAFFIC_MGMT_DIR="resources/traffic-management"

# Function to apply a YAML file
apply_yaml() {
  local file=$1
  echo "Applying $file..."
  kubectl apply -n ${NAMESPACE} -f ${TRAFFIC_MGMT_DIR}/${file}
  if [ $? -eq 0 ]; then
    echo "Successfully applied $file."
  else
    echo "Failed to apply $file."
  fi
}

# Function to delete a VirtualService or DestinationRule
delete_resource() {
  local resource_type=$1
  local resource_name=$2
  echo "Deleting ${resource_type}/${resource_name}..."
  kubectl delete -n ${NAMESPACE} ${resource_type} ${resource_name} --ignore-not-found
  if [ $? -eq 0 ]; then
    echo "Successfully deleted ${resource_type}/${resource_name}."
  else
    echo "Failed to delete ${resource_type}/${resource_name}."
  fi
}

# Function to clean up all traffic rules
cleanup_traffic_rules() {
  echo "Cleaning up all Bookinfo traffic management rules..."
  delete_resource virtualservice reviews
  delete_resource destinationrule reviews
  delete_resource envoyfilter reviews-rate-limit
  echo "Cleanup complete."
}

# Main menu
echo "Bookinfo Traffic Management Script"
echo "----------------------------------"
echo "Please choose an option:"
echo "1. Apply DestinationRule for Reviews (required for most scenarios)"
echo "2. Traffic Splitting (Reviews v1/v2 50/50)"
echo "3. Route All Traffic to Reviews v3"
echo "4. Fault Injection: Delay (Reviews v2, 7s delay)"
echo "5. Fault Injection: Abort (Reviews v1, 500 error)"
echo "6. Retries (Reviews v2, 3 attempts, 2s timeout)"
echo "7. Circuit Breaking (Reviews v2, max 1 connection/request)"
echo "8. Rate Limit (Reviews service, 1 request per 60s)"
echo "9. Traffic Mirroring (Reviews v1 to v3)"
echo "10. Content-Based Routing (Reviews v2 for 'jason', else v1)"
echo "----------------------------------"
echo "C. Clean up all traffic rules"
echo "Q. Quit"
echo "----------------------------------"

read -p "Enter your choice: " choice

case "$choice" in
  1)
    apply_yaml destination-rule-reviews.yaml
    ;;
  2)
    cleanup_traffic_rules # Clean up existing VS before applying new one
    apply_yaml destination-rule-reviews.yaml # Ensure DR is applied
    apply_yaml virtual-service-reviews-50-50.yaml
    ;;
  3)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews.yaml
    apply_yaml virtual-service-reviews-v3.yaml
    ;;
  4)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews.yaml
    apply_yaml virtual-service-reviews-fault-delay.yaml
    ;;
  5)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews.yaml
    apply_yaml virtual-service-reviews-fault-abort.yaml
    ;;
  6)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews.yaml
    apply_yaml virtual-service-reviews-retries.yaml
    ;;
  7)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews-circuit-breaker.yaml
    ;;
  8)
    cleanup_traffic_rules
    apply_yaml envoy-filter-rate-limit.yaml
    ;;
  9)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews.yaml
    apply_yaml virtual-service-reviews-mirroring.yaml
    ;;
  10)
    cleanup_traffic_rules
    apply_yaml destination-rule-reviews.yaml
    apply_yaml virtual-service-reviews-content-based-routing.yaml
    ;;
  C|c)
    cleanup_traffic_rules
    ;;
  Q|q)
    echo "Exiting script."
    ;;
  *)
    echo "Invalid choice. Please try again."
    ;;
esac

echo "Script finished."
