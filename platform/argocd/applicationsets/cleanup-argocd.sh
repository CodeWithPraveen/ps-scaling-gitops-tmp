#!/bin/bash

# This script cleans up the ArgoCD multi-cluster setup created by setup-argocd.sh
# It removes all kind clusters and cleans up kubectl contexts

set -e

echo "==================================================================="
echo "   ArgoCD Multi-Cluster Cleanup"
echo "==================================================================="
echo ""
echo "   WARNING: This will delete all kind clusters and ArgoCD setup!"
echo "   Clusters to be deleted: management, development, staging, production"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo ""

# Step 1: Kill any running port-forward processes
echo "Step 1: Stopping ArgoCD port-forward processes..."
pkill -f "kubectl port-forward svc/argocd-server" 2>/dev/null || true
echo "SUCCESS: Port-forward processes stopped"
echo ""

# Step 2: Delete target clusters
echo "Step 2: Deleting target clusters..."
for cluster in development staging production; do
  if kind get clusters 2>/dev/null | grep -q "^${cluster}$"; then
    echo "   Deleting $cluster cluster..."
    kind delete cluster --name $cluster
    echo "   SUCCESS: $cluster cluster deleted"
  else
    echo "   WARNING: $cluster cluster not found (already deleted)"
  fi
done
echo "SUCCESS: All target clusters deleted"
echo ""

# Step 3: Delete management cluster (this also removes ArgoCD)
echo "Step 3: Deleting management cluster..."
if kind get clusters 2>/dev/null | grep -q "^management$"; then
  kind delete cluster --name management
  echo "SUCCESS: Management cluster deleted (ArgoCD removed)"
else
  echo "WARNING: Management cluster not found (already deleted)"
fi
echo ""

# Step 4: Clean up kubectl contexts
echo "Step 4: Cleaning up kubectl contexts..."
for context in kind-management kind-development kind-staging kind-production; do
  if kubectl config get-contexts -o name 2>/dev/null | grep -q "^${context}$"; then
    kubectl config delete-context $context 2>/dev/null || true
    echo "   SUCCESS: Deleted context: $context"
  fi
done
echo "SUCCESS: Kubectl contexts cleaned up"
echo ""

# Step 5: Verify cleanup
echo "==================================================================="
echo "   Cleanup Complete!"
echo "==================================================================="
echo ""
echo "Remaining Kind Clusters:"
kind get clusters 2>/dev/null || echo "   (none)"
echo ""
echo "Remaining Kind Contexts:"
kubectl config get-contexts 2>/dev/null | grep kind || echo "   (none)"
echo ""
echo "You can now run setup-argocd.sh again to recreate the environment."
echo ""
