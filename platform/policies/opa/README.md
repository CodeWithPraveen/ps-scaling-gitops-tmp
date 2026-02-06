# OPA Gatekeeper for Globomantics Team Isolation

## Overview

This demonstrates using OPA Gatekeeper to enforce team isolation in Kubernetes deployments. Deployments must have the correct `team` label matching the allowed teams for each namespace.

## How It Works

### 1. ConstraintTemplate (Policy Definition)

**File**: `team-isolation-template-simple.yaml`

- Defines a new CRD: `TeamIsolation`
- Contains Rego policy logic
- Checks:
  - Deployment has a `team` label
  - Team is in the allowed list for the namespace

### 2. Constraint (Policy Instance)

**File**: `team-isolation-constraint.yaml`

- Uses the `TeamIsolation` CRD
- Specifies:
  - **Where**: `globomantics-development` namespace
  - **What**: Deployments
  - **Parameters**: `allowedTeams: [team-backend]`

### 3. Validation Flow

```
Deployment Creation Request
    ↓
Kubernetes API Server
    ↓
Gatekeeper Admission Webhook
    ↓
OPA Policy Evaluation
    ↓
Check: deployment.metadata.labels.team exists?
    ↓
Check: team in constraint.parameters.allowedTeams?
    ↓
Decision: ALLOW or DENY
```

## Test Files

### ✅ Allowed Deployment
**File**: `allowed-deployment.yaml`
```yaml
metadata:
  name: backend-api
  namespace: globomantics-development
  labels:
    team: team-backend  # Matches allowed team
```

**Result**: ✅ ALLOWED

### ❌ Denied Deployment
**File**: `denied-deployment.yaml`
```yaml
metadata:
  name: wrong-team
  namespace: globomantics-development
  labels:
    team: team-ecommerce  # NOT in allowed teams
```

**Result**: ❌ DENIED
```
Error: Team 'team-ecommerce' is not in allowed teams for this namespace: ["team-backend"]
```

## Demo Commands

```bash
# 1. Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.15/deploy/gatekeeper.yaml
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=90s

# 2. Apply policy
kubectl apply -f team-isolation-template.yaml
kubectl apply -f team-isolation-constraint.yaml

# 3. Test allowed deployment (succeeds)
kubectl apply -f allowed-deployment.yaml

# 4. Test denied deployment (fails)
kubectl apply -f denied-deployment.yaml
# Error: Team 'team-ecommerce' is not in allowed teams...

# 5. Check violations
kubectl get teamisolation team-backend-isolation -o yaml
```

## Key Benefits

**vs ArgoCD AppProjects:**
- ArgoCD controls *where* apps can deploy
- OPA controls *what* gets deployed (labels, images, security context, etc.)

**Enforcement Point:**
- Runs at Kubernetes admission controller level
- Blocks invalid resources before they're created
- Works for kubectl, Helm, ArgoCD, or any deployment method

## Architecture

```
┌─────────────────────────────────────────┐
│  ConstraintTemplate (Reusable Policy)  │
│  - Defines TeamIsolation CRD           │
│  - Contains Rego validation logic      │
└────────────────┬────────────────────────┘
                 │
                 │ Creates CRD
                 ▼
┌─────────────────────────────────────────┐
│  Constraint (Policy Instance)           │
│  - namespace: globomantics-development  │
│  - allowedTeams: [team-backend]         │
└────────────────┬────────────────────────┘
                 │
                 │ Validates
                 ▼
┌─────────────────────────────────────────┐
│  Deployment with team: team-ecommerce   │
│  ❌ DENIED                              │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Deployment with team: team-backend     │
│  ✅ ALLOWED                             │
└─────────────────────────────────────────┘
```

## Why the Original Policy Failed

The original policy tried to use `data.inventory.namespace` which requires:
1. Gatekeeper Config to sync namespace data
2. Namespace labels to exist
3. Data sync to complete before validation

**Issues:**
- Sync is async and unreliable after restarts
- Adds complexity and failure points
- Harder to troubleshoot

**Solution:** Use constraint parameters instead of external data for simpler, more reliable policies.
