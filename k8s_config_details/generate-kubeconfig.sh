#!/bin/bash
################################################################################
# Script: generate-kubeconfig.sh
# Purpose: Generate kubeconfig file for Jenkins automation
# Designed and Developed by: sak_shetty
################################################################################

# ---------------------------- Colors for Logging ------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"; }
log_error()   { echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"; }

# ---------------------------- Variables --------------------------------------
OUTPUT_DIR="$HOME/kubeconfig_for_jenkins"
KUBECONFIG_FILE="$OUTPUT_DIR/kubeconfig.yaml"

# ---------------------------- Main Script ------------------------------------
log_info "Creating output directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

log_info "Copying /etc/kubernetes/admin.conf to $KUBECONFIG_FILE ..."
if sudo cp /etc/kubernetes/admin.conf "$KUBECONFIG_FILE"; then
    sudo chown $(whoami):$(whoami) "$KUBECONFIG_FILE"
    log_success "Kubeconfig successfully saved at: $KUBECONFIG_FILE"
else
    log_error "Failed to copy kubeconfig!"
    exit 1
fi

log_info "Verifying Kubernetes cluster nodes..."
kubectl --kubeconfig="$KUBECONFIG_FILE" get nodes

log_info "Displaying Kubernetes cluster info:"
kubectl --kubeconfig="$KUBECONFIG_FILE" version --short

# ---------------------------- Footer Instructions -----------------------------
log_success "Kubeconfig generation completed. Ready for Jenkins."
echo "================================================"
echo "After this, you will have a file: in this path"
echo "/home/ubuntu/kubeconfig_for_jenkins/kubeconfig.yaml"
echo "================================================="
echo "On Jenkins Server: Before executing this file fetch-and-prepare-kubeconfig.sh"
echo "Edit the variables at the top of fetch-and-prepare-kubeconfig.sh:"
echo "CONTROL_PLANE_IP → your kubeadm master IP"
echo "CONTROL_PLANE_USER → the SSH user"
echo "================================================"

################################################################################
# End of Script
# Designed and Developed by: sak_shetty
################################################################################
