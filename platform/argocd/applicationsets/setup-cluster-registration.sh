#!/bin/bash

# This script is used to manually register Kind clusters with ArgoCD
# It creates a service account and cluster role binding in the target cluster
# It then creates a token secret in the target cluster
# It then creates a cluster secret in ArgoCD
# It then verifies the registration

set -e

echo "=== Manual ArgoCD Cluster Registration for Kind Clusters ==="
echo "This script creates cluster secrets directly in ArgoCD"
echo ""

# Function to create cluster secret
create_cluster_secret() {
  local CONTEXT=$1
  local CLUSTER_NAME=$2
  local ENV_LABEL=$3
  local SERVER_URL=$4
  
  echo ""
  echo "=== Processing $CLUSTER_NAME ==="
  
  # Switch to target cluster to create service account and get token
  kubectl --context=$CONTEXT create namespace kube-system --dry-run=client -o yaml | kubectl --context=$CONTEXT apply -f - 2>/dev/null || true
  kubectl --context=$CONTEXT create serviceaccount argocd-manager -n kube-system --dry-run=client -o yaml | kubectl --context=$CONTEXT apply -f -
  
  # Create cluster role and binding
  cat <<YAML | kubectl --context=$CONTEXT apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-manager-role
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-manager-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-manager-role
subjects:
- kind: ServiceAccount
  name: argocd-manager
  namespace: kube-system
YAML

  # Create token secret for the service account
  cat <<YAML | kubectl --context=$CONTEXT apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: argocd-manager-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: argocd-manager
type: kubernetes.io/service-account-token
YAML

  # Wait for token to be populated
  echo "Waiting for token..."
  sleep 3
  
  # Get the token
  TOKEN=$(kubectl --context=$CONTEXT get secret argocd-manager-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)
  
  # Get CA certificate
  CA_CERT=$(kubectl --context=$CONTEXT get secret argocd-manager-token -n kube-system -o jsonpath='{.data.ca\.crt}')
  
  # Create ArgoCD cluster secret in management cluster
  cat <<YAML | kubectl --context=kind-management apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: cluster-$CLUSTER_NAME
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    env: $ENV_LABEL
type: Opaque
stringData:
  name: $CLUSTER_NAME
  server: $SERVER_URL
  config: |
    {
      "bearerToken": "$TOKEN",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "$CA_CERT"
      }
    }
YAML

  echo "SUCCESS: $CLUSTER_NAME registered"
}

# Register each cluster
create_cluster_secret "kind-development" "development" "development" "https://development-control-plane:6443"
create_cluster_secret "kind-staging" "staging" "staging" "https://staging-control-plane:6443"
create_cluster_secret "kind-production" "production" "production" "https://production-control-plane:6443"

echo ""
echo "=== Verifying Registration ==="
kubectl --context=kind-management get secrets -n argocd -l argocd.argoproj.io/secret-type=cluster
echo ""
echo "=== ArgoCD Cluster List ==="
argocd cluster list

