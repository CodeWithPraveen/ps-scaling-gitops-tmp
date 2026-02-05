#!/bin/bash

# This script cleans up the cluster setup created by setup-cluster-registration.sh
# It removes cluster secrets from ArgoCD and service accounts/RBAC from target clusters

set -e

echo "==================================================================="
echo "   ArgoCD Cluster Setup Cleanup"
echo "==================================================================="
echo ""
echo "This script will remove cluster registrations from ArgoCD"
echo ""

# Function to cleanup cluster registration
cleanup_cluster_registration() {
  local CONTEXT=$1
  local CLUSTER_NAME=$2
  
  echo "Processing $CLUSTER_NAME..."
  
  # Check if target cluster exists
  if ! kubectl config get-contexts -o name | grep -q "^${CONTEXT}$"; then
    echo "   WARNING: Context $CONTEXT not found, skipping target cluster cleanup"
  else
    # Delete token secret
    kubectl --context=$CONTEXT delete secret argocd-manager-token -n kube-system --ignore-not-found=true
    echo "   SUCCESS: Deleted token secret"
    
    # Delete cluster role binding
    kubectl --context=$CONTEXT delete clusterrolebinding argocd-manager-role-binding --ignore-not-found=true
    echo "   SUCCESS: Deleted cluster role binding"
    
    # Delete cluster role
    kubectl --context=$CONTEXT delete clusterrole argocd-manager-role --ignore-not-found=true
    echo "   SUCCESS: Deleted cluster role"
    
    # Delete service account
    kubectl --context=$CONTEXT delete serviceaccount argocd-manager -n kube-system --ignore-not-found=true
    echo "   SUCCESS: Deleted service account"
  fi
  
  # Delete ArgoCD cluster secret from management cluster
  if kubectl config get-contexts -o name | grep -q "^kind-management$"; then
    kubectl --context=kind-management delete secret cluster-$CLUSTER_NAME -n argocd --ignore-not-found=true
    echo "   SUCCESS: Deleted cluster secret from ArgoCD"
  else
    echo "   WARNING: Management cluster not found, skipping cluster secret deletion"
  fi
  
  echo "SUCCESS: $CLUSTER_NAME cleanup complete"
  echo ""
}

# Cleanup each cluster
cleanup_cluster_registration "kind-development" "development"
cleanup_cluster_registration "kind-staging" "staging"
cleanup_cluster_registration "kind-production" "production"

echo "==================================================================="
echo "   Cleanup Complete!"
echo "==================================================================="
echo ""

# Verify cleanup if management cluster exists
if kubectl config get-contexts -o name | grep -q "^kind-management$"; then
  echo "Remaining ArgoCD cluster secrets:"
  kubectl --context=kind-management get secrets -n argocd -l argocd.argoproj.io/secret-type=cluster 2>/dev/null || echo "   (none)"
  echo ""
  echo "ArgoCD cluster list:"
  argocd cluster list 2>/dev/null || echo "   (ArgoCD CLI not connected)"
  echo ""
fi

echo "You can now run setup-cluster-registration.sh again to re-register clusters."
echo ""
