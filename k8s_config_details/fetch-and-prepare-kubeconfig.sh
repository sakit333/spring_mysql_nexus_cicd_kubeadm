#!/bin/bash
################################################################################
# Script: fetch-and-prepare-kubeconfig.sh
# Purpose: Automate copying kubeconfig from kubeadm control plane to Jenkins
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

# ---------------------------- User Input -------------------------------------
echo -e "${YELLOW}Please provide the following details:${NC}"
read -rp "Enter the SSH user for control plane (default: ubuntu): " CONTROL_PLANE_USER
CONTROL_PLANE_USER=${CONTROL_PLANE_USER:-ubuntu}

read -rp "Enter the control plane PUBLIC IP (or PRIVATE IP if Jenkins is on same VPC): " CONTROL_PLANE_IP
if [ -z "$CONTROL_PLANE_IP" ]; then
    log_error "Control plane IP cannot be empty!"
    exit 1
fi

# ---------------------------- Variables --------------------------------------
REMOTE_KUBECONFIG="/home/$CONTROL_PLANE_USER/kubeconfig_for_jenkins/kubeconfig.yaml"
LOCAL_DEST_DIR="/home/jenkins/kubeconfig_for_jenkins"
JENKINS_CREDENTIAL_ID="kubeconfig-credentials-id"

# ---------------------------- Main Script ------------------------------------
mkdir -p "$LOCAL_DEST_DIR"

log_info "Copying kubeconfig from control plane ($CONTROL_PLANE_USER@$CONTROL_PLANE_IP) ..."
scp "${CONTROL_PLANE_USER}@${CONTROL_PLANE_IP}:${REMOTE_KUBECONFIG}" "$LOCAL_DEST_DIR/kubeconfig.yaml"
if [ $? -eq 0 ]; then
    log_success "Kubeconfig copied successfully to $LOCAL_DEST_DIR/kubeconfig.yaml"
else
    log_error "Failed to copy kubeconfig from control plane!"
    exit 1
fi

log_info "Setting secure permissions for kubeconfig..."
chmod 600 "$LOCAL_DEST_DIR/kubeconfig.yaml"

# Test kubectl access
export KUBECONFIG="$LOCAL_DEST_DIR/kubeconfig.yaml"
log_info "Testing kubectl connectivity..."
if kubectl get nodes &>/dev/null; then
    log_success "Kubectl access verified!"
else
    log_error "Kubectl cannot connect to cluster. Check network and kubeconfig!"
    exit 1
fi

log_info "Kubeconfig ready for Jenkins usage."
log_info "You can upload as 'Secret File' in Jenkins credentials."
log_info "Credential ID to use in Jenkinsfile: $JENKINS_CREDENTIAL_ID"

# ---------------------------- Instructions -----------------------------------
log_success "Fetch and preparation of kubeconfig completed."
echo "==============================================================="
echo "After this, follow this procedure to add Jenkins credentials:"
echo "1. Go to Jenkins Web UI → Manage Jenkins → Credentials → System → Global credentials (unrestricted)."
echo "2. Click Add Credentials."
echo "3. Kind: Secret file"
echo "4. File: Browse and select kubeconfig.yaml from $LOCAL_DEST_DIR/kubeconfig.yaml"
echo "5. ID: kubeconfig-credentials-id (this is what your KUBECONFIG_CREDENTIALS variable should match)"
echo "6. Description: Kubeconfig for kubeadm cluster"
echo "7. Click OK to save."
echo "8. After these Run Jenkins Build...!!!!"
echo "==============================================================="

################################################################################
# End of Script
# Designed and Developed by: sak_shetty
################################################################################
