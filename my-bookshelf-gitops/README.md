# My Bookshelf GitOps 🔄

> GitOps repository for the My Bookshelf application - managing Kubernetes deployments with ArgoCD, featuring automated synchronization, secret management, and comprehensive monitoring stack.

## 📋 Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Applications](#applications)
- [Deployment Strategy](#deployment-strategy)
- [Secret Management](#secret-management)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Application Management](#application-management)
- [Monitoring & Logging](#monitoring--logging)
- [Troubleshooting](#troubleshooting)
- [Related Repositories](#related-repositories)

## 🎯 Overview

This GitOps repository implements the App of Apps pattern with ArgoCD to manage all Kubernetes resources for the My Bookshelf project. It provides:

- **Automated deployments** from Git commits
- **Self-healing** infrastructure
- **Secret management** via External Secrets Operator
- **Complete observability** with Prometheus, Grafana, and EFK stack
- **SSL/TLS certificates** with cert-manager
- **Ingress routing** with NGINX

## 📁 Repository Structure

```
my-bookshelf-gitops/
├── apps/                      # ArgoCD Application definitions
│   ├── app-of-apps.yaml      # Root application
│   ├── bookshelf-app.yaml    # Main application
│   ├── cert-manager.yaml     # SSL certificate management
│   ├── external-secrets.yaml # Secret management
│   ├── ingress-nginx.yaml    # Ingress controller
│   ├── manifests.yaml        # Core K8s resources
│   ├── prometheus-grafana.yaml # Monitoring stack
│   ├── sonarqube.yaml        # Code quality
│   └── efk/                  # Logging stack
│       ├── efk-elasticsearch.yaml
│       ├── efk-fluent-bit.yaml
│       └── efk-kibana.yaml
├── bookshelf-app/            # Helm chart for main app
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── bookshelf-ingress.yaml
├── cert-manager/             # Cert-manager config
├── external-secrets/         # ESO configuration
├── ingress-nginx/           # Ingress controller setup
├── manifests/               # Core K8s manifests
│   ├── cluster-issuer.yaml
│   ├── externalsecret-*.yaml
│   ├── secretstore-*.yaml
│   ├── storageclass.yaml
│   └── servicemonitor.yaml
└── namespaces/              # Namespace definitions
```

## 🚀 Applications

### Core Applications

| Application | Purpose | Namespace | Sync Wave |
|------------|---------|-----------|-----------|
| **external-secrets** | Manages secrets from AWS Secrets Manager | secrets | -2 |
| **bookshelf-app** | Main application (Backend + PostgreSQL) | bookshelf-app | -1 |
| **manifests** | Core Kubernetes resources | default | 0 |
| **ingress-nginx** | Ingress controller | ingress-nginx | 0 |
| **cert-manager** | SSL/TLS certificate management | cert-manager | 0 |

### Observability Stack

| Application | Purpose | Access |
|------------|---------|--------|
| **prometheus-grafana** | Metrics collection and visualization | Internal |
| **sonarqube** | Code quality analysis | LoadBalancer |
| **EFK Stack** | Centralized logging | Internal |

## 🔄 Deployment Strategy

### Sync Waves
Applications deploy in ordered waves to ensure dependencies are met:
1. **Wave -2**: External Secrets Operator
2. **Wave -1**: Bookshelf application
3. **Wave 0**: Supporting services (ingress, manifests)
4. **No wave**: Monitoring and logging tools

### Sync Policy
All applications use automated sync with:
- **Auto-prune**: Remove resources not in Git
- **Self-heal**: Revert manual changes
- **Create namespace**: Auto-create namespaces

## 🔐 Secret Management

### External Secrets Configuration
The repository uses External Secrets Operator to sync secrets from AWS Secrets Manager:

**Database Credentials**
- Secret: `my-bookshelf/db-creds`
- Target: `db-creds` in `bookshelf-db` namespace

**ArgoCD Repository Access**
- Secret: `max-argocd-git-ssh-key`
- Target: `repo-gitlab-ssh` in `argocd` namespace

### Secret Stores
- `bookshelf-app`: Application secrets
- `bookshelf-db`: Database credentials
- `argocd`: Repository SSH keys

## 📋 Prerequisites

Before using this repository:

1. **Infrastructure deployed** via `my-bookshelf-infra`
   - EKS cluster running
   - ArgoCD installed
   - External Secrets Operator configured

2. **AWS Secrets created**:
   ```bash
   # Database credentials
   aws secretsmanager create-secret \
     --name my-bookshelf/db-creds \
     --secret-string '{
       "POSTGRES_USER":"postgres",
       "POSTGRES_PASSWORD":"your-password",
       "POSTGRES_DB":"books"
     }'
   ```

3. **DNS configured**
   - Domain: `mybookshelf.ddns.net`
   - Pointing to ingress LoadBalancer

4. **CloudFront & S3** (manually created)
   - S3 bucket with frontend static files
   - CloudFront distribution: https://d29uf7fg4cztcx.cloudfront.net

## 🚀 Getting Started

### 1. Deploy App of Apps

The App of Apps is deployed automatically by the infrastructure repository. To manually deploy:

```bash
kubectl apply -f apps/app-of-apps.yaml
```

### 2. Verify Applications

```bash
# Check all applications
kubectl get applications -n argocd

# Check sync status
argocd app list

# Check specific app
argocd app get bookshelf-app
```

### 3. Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at https://localhost:8080
```

## 📱 Application Management

### Update Application Version

1. **Update image tag** in `bookshelf-app/values.yaml`:
```yaml
backend:
  image:
    tag: v0.0.26  # New version
```

2. **Commit and push**:
```bash
git add bookshelf-app/values.yaml
git commit -m "chore: update bookshelf app to v0.0.26"
git push
```

3. **ArgoCD auto-syncs** within 3 minutes

### Manual Sync
```bash
argocd app sync bookshelf-app
```

### Rollback
```bash
# Via ArgoCD UI or CLI
argocd app rollback bookshelf-app REVISION
```

## 📊 Monitoring & Logging

### Prometheus & Grafana
- **Metrics collection** from all services
- **Pre-configured dashboards** for Kubernetes
- **Resource limits** optimized for small clusters

Access Grafana:
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Default credentials: admin/prom-operator
```

### EFK Stack
- **Elasticsearch**: Log storage (10Gi volume)
- **Fluent Bit**: Log collection from all pods
- **Kibana**: Log visualization

Access Kibana:
```bash
kubectl port-forward -n efk svc/kibana-kibana 5601:5601
```

### SonarQube
- **Code quality** metrics from CI/CD
- **LoadBalancer** service for external access

## 🔧 Troubleshooting

### Application Not Syncing

```bash
# Check application status
argocd app get bookshelf-app

# Force refresh
argocd app refresh bookshelf-app

# Check logs
kubectl logs -n argocd deployment/argocd-repo-server
```

### Secret Issues

```bash
# Verify secret store
kubectl get secretstore -A

# Check external secret status
kubectl describe externalsecret db-creds -n bookshelf-db

# ESO logs
kubectl logs -n secrets deployment/external-secrets
```

### Database Connection

```bash
# Check PostgreSQL pod
kubectl get pods -n bookshelf-db

# Verify secret
kubectl get secret db-creds -n bookshelf-db -o yaml

# Test connection
kubectl exec -it -n bookshelf-app deployment/bookshelf-backend -- \
  psql $DATABASE_URL -c "SELECT 1"
```

### Ingress/TLS Issues

```bash
# Check ingress
kubectl describe ingress bookshelf -n bookshelf-app

# Certificate status
kubectl get certificate -A

# Cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

## 🔗 Related Repositories

### my-bookshelf-app
- Application source code
- CI/CD pipeline
- Pushes images to ECR

### my-bookshelf-infra
- AWS infrastructure (Terraform)
- EKS cluster setup
- ArgoCD bootstrap

## 🏷️ Best Practices

1. **Never commit secrets** - Use External Secrets
2. **Version everything** - Tag all image versions
3. **Use sync waves** - Ensure proper deployment order
4. **Set resource limits** - Prevent resource exhaustion
5. **Monitor everything** - Use provided observability tools

---

**Maintainer:** Max Develeap  
**Email:** max@develeap.com  
**Repository:** [GitLab - my-bookshelf-gitops](https://gitlab.com/maxopsdeveleap/my-bookshelf-gitops)
