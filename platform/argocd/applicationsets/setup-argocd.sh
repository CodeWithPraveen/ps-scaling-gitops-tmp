#!/bin/bash
set -e

echo "==================================================================="
echo "   ArgoCD Multi-Cluster Demo Setup"
echo "==================================================================="
echo ""

# Step 1: Create management cluster for ArgoCD
echo "Step 1: Creating management cluster for ArgoCD..."
kind create cluster --name management
echo "SUCCESS: Management cluster created"
echo ""

# Step 2: Install ArgoCD
echo "Step 2: Installing ArgoCD in management cluster..."
kubectl create namespace argocd
kubectl apply --server-side=true -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "SUCCESS: ArgoCD installation initiated"
echo ""

# Step 3: Wait for ArgoCD to be ready
echo "Step 3: Waiting for ArgoCD to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
echo "SUCCESS: ArgoCD is ready"
echo ""

# Step 4: Create target clusters
echo "Step 4: Creating target clusters (development, staging, production)..."
kind create cluster --name development &
kind create cluster --name staging &
kind create cluster --name production &
wait
echo "SUCCESS: All target clusters created"
echo ""

# Switch back to management cluster
kubectl config use-context kind-management

# Step 5: Port-forward ArgoCD
echo "Step 5: Setting up port-forward to ArgoCD..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
PORTFWD_PID=$!
sleep 3
echo "SUCCESS: Port-forward running (PID: $PORTFWD_PID)"
echo ""

# Step 6: Get admin password and login
echo "Step 6: Logging into ArgoCD..."
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
echo "   ArgoCD Admin Password: $ARGOCD_PASSWORD"
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure
echo "SUCCESS: Logged in to ArgoCD"
echo ""

# Step 7: Register clusters with ArgoCD (Skipped for Kind clusters)
# echo "Step 7: Registering clusters with ArgoCD..."
# echo "   This creates service accounts and RBAC in each cluster..."
# argocd cluster add kind-development --name development --label env=development --yes
# argocd cluster add kind-staging --name staging --label env=staging --yes
# argocd cluster add kind-production --name production --label env=production --yes
# echo "SUCCESS: All clusters registered"
# echo ""

# Step 8: Verify setup
echo "==================================================================="
echo "   Setup Complete!"
echo "==================================================================="
echo ""
echo "Registered Clusters:"
argocd cluster list
echo ""
echo "Kind Clusters:"
kind get clusters
echo ""
echo "Kubernetes Contexts:"
kubectl config get-contexts | grep kind
echo ""