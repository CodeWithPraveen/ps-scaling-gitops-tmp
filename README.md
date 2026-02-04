# Scaling GitOps for Enterprise Environments

This repository demonstrates enterprise GitOps patterns with ArgoCD and Kubernetes. It accompanies the Pluralsight course "Scaling GitOps for Enterprise Environments".

## Repository Structure

```
ps-scaling-gitops-tmp/
├── platform/                    # Platform team owned resources
│   ├── argocd/
│   │   ├── applicationsets/     # Multi-cluster deployment patterns
│   │   ├── projects/            # Team isolation and RBAC
│   │   └── ha/                  # High availability configuration
│   ├── policies/
│   │   └── kyverno/             # Security and compliance policies
│   └── rbac/                    # Kubernetes RBAC for tenants
│
├── applications/                # Application team owned resources
│   ├── backend/                 # Backend API service
│   │   ├── base/                # Base Kustomize configuration
│   │   └── overlays/            # Environment-specific overlays
│   │       ├── development/
│   │       ├── staging/
│   │       └── production/
│   └── ecommerce/               # Microservices application
│       ├── app-of-apps.yaml     # Parent application
│       ├── applications/        # Child application definitions
│       └── services/            # Service manifests
│           ├── database/
│           ├── api-gateway/
│           └── frontend/
│
├── migrations/                  # Database migration patterns
│   ├── application.yaml
│   ├── migration-job.yaml
│   └── deployment.yaml
│
└── examples/                    # Test and demo examples
    ├── compliant-deployment.yaml
    ├── noncompliant-deployment.yaml
    ├── image-updater-app.yaml
    └── oci-helm-app.yaml
```

## Course Modules Mapping

| Module | Topic | Directory |
|--------|-------|-----------|
| Module 1 | Multi-Cluster GitOps | `platform/argocd/applicationsets/`, `platform/argocd/projects/`, `platform/rbac/` |
| Module 2 | Policy-Based Governance | `platform/policies/kyverno/`, `examples/` |
| Module 3 | Performance & Reliability | `platform/argocd/ha/`, `applications/backend/` |
| Module 4 | Enterprise Solutions | `applications/ecommerce/`, `migrations/` |

## Key Patterns Demonstrated

### Multi-Cluster Deployment (Module 1)
- **Cluster Generator**: Auto-discover and deploy to clusters by labels
- **List Generator**: Explicit environment targeting
- **Multi-Tenancy**: ArgoCD Projects and Kubernetes RBAC for team isolation

### Policy-Based Governance (Module 2)
- **Kyverno Policies**: Require resources, disallow privileged, allowed registries
- **Audit Mode**: Best practices auditing without blocking

### Performance & Reliability (Module 3)
- **High Availability**: Controller sharding, Redis HA, resource allocation
- **Kustomize Overlays**: Environment-specific configurations

### Enterprise Solutions (Module 4)
- **App-of-Apps**: Managing microservices with sync waves
- **Database Migrations**: PreSync hooks for schema changes
- **Image Updater**: Automated image tag updates

## Prerequisites

- Kubernetes cluster (1.25+)
- ArgoCD (2.8+)
- Kyverno (1.10+) for policy enforcement
- kubectl and argocd CLI

## Quick Start

1. **Install ArgoCD**:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Apply Platform Configurations**:
   ```bash
   # Apply Kyverno policies
   kubectl apply -f platform/policies/kyverno/

   # Apply ArgoCD projects
   kubectl apply -f platform/argocd/projects/
   ```

3. **Deploy Applications**:
   ```bash
   # Deploy backend using ApplicationSet
   kubectl apply -f platform/argocd/applicationsets/list-generator.yaml

   # Or deploy microservices using app-of-apps
   kubectl apply -f applications/ecommerce/app-of-apps.yaml
   ```

## Testing Policies

```bash
# This should be blocked by Kyverno
kubectl apply -f examples/noncompliant-deployment.yaml

# This should succeed
kubectl apply -f examples/compliant-deployment.yaml
```

## Course Information

- **Course**: Scaling GitOps for Enterprise Environments
- **Platform**: Pluralsight
- **Author**: Praveen
- **Organization**: Globomantics (fictional)

## License

This code is provided for educational purposes as part of the Pluralsight course.
