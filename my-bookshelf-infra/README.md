# My Bookshelf Infrastructure 🏗️

> Infrastructure as Code (IaC) repository for the My Bookshelf application - provisioning AWS resources with Terraform including EKS cluster, networking, and GitOps tooling.

## 📋 Table of Contents

- [Overview](#overview)
- [Infrastructure Components](#infrastructure-components)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Deployment Flow](#deployment-flow)
- [Terraform Modules](#terraform-modules)
- [State Management](#state-management)
- [GitOps Integration](#gitops-integration)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Related Repositories](#related-repositories)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This repository contains Terraform code to provision and manage the AWS infrastructure for the My Bookshelf application. It creates a production-ready Kubernetes environment with EKS, implements GitOps with ArgoCD, and follows AWS best practices for security and networking.

## 🏛️ Infrastructure Components

### Core Infrastructure
- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **EKS Cluster**: Managed Kubernetes cluster with OIDC provider
- **Node Groups**: Auto-scaling EC2 instances (t3a.medium)
- **Networking**: NAT Gateway, Internet Gateway, route tables

### Kubernetes Add-ons
- **ArgoCD**: GitOps continuous delivery tool
- **AWS EBS CSI Driver**: Enables EKS cluster to manage EBS volumes for persistent storage
- **External Secrets Operator (ESO)**: AWS Secrets Manager integration

### Security Components
- **IAM Roles**: Service-specific roles with least privilege
- **IRSA**: IAM Roles for Service Accounts
  - EBS CSI Driver service account role
  - ESO service account role for Secrets Manager access
- **OIDC Provider**: Secure workload identity

## 🏗️ Architecture

The infrastructure creates a highly available, secure AWS environment:

**Network Architecture:**
- VPC with CIDR: 10.20.0.0/16
- 2 Public Subnets: 10.20.1.0/24, 10.20.2.0/24 (for load balancers)
- 2 Private Subnets: 10.20.101.0/24, 10.20.102.0/24 (for EKS nodes)
- NAT Gateway in public subnet for outbound internet access
- Internet Gateway for public subnet connectivity

**EKS Architecture:**
- Managed control plane across multiple AZs
- Worker nodes in private subnets
- OIDC provider for secure workload identity
- Node group with auto-scaling (min: 2, max: 3, desired: 3)

## 📋 Prerequisites

### Required Tools
- Terraform >= 1.3.0
- AWS CLI configured with appropriate credentials
- kubectl >= 1.28
- Helm >= 3.0
- Git

### AWS Permissions
Your AWS user/role needs permissions to create:
- VPC and networking resources
- EKS clusters and node groups
- IAM roles and policies
- Secrets Manager access
- S3 bucket access (for Terraform state)

### Existing Resources
The following resources must exist before running Terraform:
- S3 bucket for Terraform state (configure in your `terraform.tfvars`)
- AWS Secrets Manager secret for GitLab SSH key (configure in your `terraform.tfvars`)

### Configuration Files
Before deploying, you need:
- `terraform.tfvars` file with your custom values (copy from `terraform.tfvars.example`)

### Manually Created Resources
The following are created outside of Terraform:
- CloudFront distribution for frontend delivery
- S3 bucket for static frontend files (HTML, CSS, JS)

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://gitlab.com/maxopsdeveleap/my-bookshelf-infra.git
cd my-bookshelf-infra
```

### 2. Configure Variables
```bash
# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit with your custom values
nano terraform.tfvars
```

**Customize these key settings in `terraform.tfvars`:**
```hcl
# Update with your information
project = "your-name-my-bookshelf"
global_tags = {
  owner = "your.name"
  # ... other tags
}

# Choose your setup size
node_instance_type     = "t3a.medium"  # or "t3a.small" for cost savings
node_desired_capacity  = 3             # or 2 for cost savings
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review the Plan
```bash
terraform plan
```

### 5. Apply Infrastructure
```bash
terraform apply
```

This will create:
- VPC with configurable CIDR and subnets
- EKS cluster named `{your-project}-eks`
- Node group with your specified instance type and capacity
- ArgoCD installation in `argocd` namespace
- App of Apps pattern for GitOps

### 6. Configure kubectl
```bash
# Update cluster name to match your project variable
aws eks update-kubeconfig --region ap-south-1 --name {your-project}-eks
```

### 7. Verify ArgoCD Installation
```bash
kubectl get pods -n argocd
kubectl get secret -n argocd repo-gitlab-ssh -o yaml
```

## 🚀 Deployment Flow

### What Happens After `terraform apply`

The deployment follows this automated sequence with estimated timelines:

#### Phase 1: Infrastructure Foundation (0-8 minutes)
**Terraform creates the AWS resources in dependency order:**

1. **VPC & Networking** (1-2 minutes)
   - VPC with CIDR 10.20.0.0/16
   - 2 public subnets (10.20.1.0/24, 10.20.2.0/24)
   - 2 private subnets (10.20.101.0/24, 10.20.102.0/24)
   - Internet Gateway and NAT Gateway
   - Route tables and associations

2. **IAM Roles & Policies** (1-2 minutes)
   - EKS cluster service role
   - Node group instance role
   - EBS CSI driver role with IRSA
   - External Secrets Operator role with IRSA

3. **EKS Cluster** (3-5 minutes)
   - Managed control plane across 2 AZs
   - OIDC provider for service account authentication
   - Private and public endpoint access

4. **Node Group** (2-3 minutes)
   - 2-3 t3a.medium EC2 instances
   - Auto-scaling group configuration
   - Instances join cluster automatically

5. **EKS Add-ons** (1-2 minutes)
   - AWS EBS CSI driver installation
   - Required for persistent volume support

#### Phase 2: ArgoCD Bootstrap (8-12 minutes)
**Terraform deploys GitOps foundation:**

1. **ArgoCD Helm Installation** (3-4 minutes)
   ```bash
   # Terraform waits for EKS cluster and nodes to be ready
   depends_on = [module.eks, module.node_group]
   ```
   - ArgoCD server, repo-server, application-controller
   - Redis for caching
   - Dex for authentication

2. **Repository SSH Secret** (30 seconds)
   ```bash
   # Reads from AWS Secrets Manager
   depends_on = [helm_release.argocd]
   ```
   - Fetches SSH key from `max-argocd-git-ssh-key`
   - Creates Kubernetes secret `repo-gitlab-ssh`
   - Configures ArgoCD repository access

3. **App-of-Apps Deployment** (30 seconds)
   ```bash
   # Creates the root ArgoCD application
   depends_on = [helm_release.argocd, kubernetes_secret.argocd_repo_ssh]
   ```
   - Deploys app-of-apps.yaml manifest
   - Points to `my-bookshelf-gitops` repository

#### Phase 3: GitOps Synchronization (12-18 minutes)
**ArgoCD automatically discovers and deploys applications in sync waves:**

**Sync Wave -2: External Secrets (2-3 minutes)**
- External Secrets Operator installation
- Service accounts with IRSA annotations
- Secret stores for AWS Secrets Manager authentication
- Enables secure secret retrieval from AWS

**Sync Wave -1: Application Prerequisites (3-4 minutes)**
- Bookshelf application Helm chart deployment
- PostgreSQL database with persistent volume
- Database credentials synchronized from AWS Secrets Manager
- `bookshelf-db` namespace creation

**Sync Wave 0: Core Manifests (2-3 minutes)**
- Cluster issuer for Let's Encrypt certificates
- Default storage class (gp2-csi)
- Service monitors for Prometheus
- Additional external secrets and secret stores

**No Sync Wave: Supporting Services (5-8 minutes)**
- **NGINX Ingress Controller**: Load balancer and routing
- **Cert-manager**: Automatic TLS certificate provisioning
- **Prometheus & Grafana**: Monitoring stack with dashboards
- **SonarQube**: Code quality analysis platform

#### Phase 4: Application Ready (18-25 minutes)
**Final configuration and health checks:**

1. **TLS Certificate Provisioning** (2-3 minutes)
   - Let's Encrypt certificate for `mybookshelf.ddns.net`
   - Automatic DNS validation
   - Certificate installation in ingress

2. **Database Initialization** (1-2 minutes)
   - PostgreSQL schema creation
   - Application database connectivity verified

3. **Health Checks & Readiness** (1-2 minutes)
   - All pods reach Ready state
   - Ingress controller operational
   - Load balancer DNS propagation

### Real-time Monitoring Commands

**Track Infrastructure Progress:**
```bash
# Monitor Terraform progress
terraform apply -auto-approve

# Watch EKS cluster creation
aws eks describe-cluster --name max-my-bookshelf-eks --region ap-south-1 --query 'cluster.status'

# Check node readiness
kubectl get nodes -w
```

**Monitor ArgoCD Deployment:**
```bash
# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name max-my-bookshelf-eks

# Watch ArgoCD pods
kubectl get pods -n argocd -w

# Verify repository secret
kubectl get secret repo-gitlab-ssh -n argocd -o jsonpath='{.data.sshPrivateKey}' | base64 -d | head -1
```

**Track Application Sync:**
```bash
# Watch all ArgoCD applications
kubectl get applications -n argocd -w

# Check sync status
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status

# Monitor specific application
kubectl describe application bookshelf-app -n argocd
```

**Verify Complete Deployment:**
```bash
# Check all namespaces
kubectl get pods -A

# Verify ingress and certificates
kubectl get ingress -A
kubectl get certificates -A

# Test application health
curl -k https://mybookshelf.ddns.net/health
```

### Expected End State

After successful deployment, you should have:

**Infrastructure:**
- ✅ VPC with your configured subnet layout
- ✅ EKS cluster with your specified node configuration
- ✅ ArgoCD running and syncing applications

**Applications:**
- ✅ Bookshelf backend API accessible via HTTPS
- ✅ PostgreSQL database with persistent storage
- ✅ Monitoring stack (Prometheus/Grafana) operational
- ✅ Ingress controller managing traffic
- ✅ Valid TLS certificates

**Security:**
- ✅ All secrets managed via External Secrets Operator
- ✅ IRSA roles providing secure AWS access
- ✅ Network policies and security groups active

### Configuration Management

**To modify your deployment:**
1. Edit your `terraform.tfvars` file
2. Run `terraform plan` to see changes
3. Run `terraform apply` to implement changes

**Common customizations:**
```hcl
# Cost optimization
node_instance_type = "t3a.small"
node_desired_capacity = 2

# Scale up for production
node_instance_type = "t3a.large" 
node_desired_capacity = 5

# Different region
aws_region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
```

### Troubleshooting Timeline Issues

**If deployment stalls at any phase:**

```bash
# Check Terraform state
terraform show | grep -A 10 "resource_changes"

# Verify AWS resources
aws eks list-clusters --region ap-south-1
aws eks describe-nodegroup --cluster-name max-my-bookshelf-eks --nodegroup-name max-node-group --region ap-south-1

# ArgoCD troubleshooting
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-repo-server
```

## 📦 Terraform Modules

### VPC Module (`modules/vpc`)
Creates the network foundation:
- VPC with DNS support enabled
- Public subnets with auto-assign public IP
- Private subnets for EKS nodes
- NAT Gateway for outbound traffic from private subnets
- Route tables and associations
- Proper tagging for EKS integration

### EKS Module (`modules/eks`)
Provisions the Kubernetes cluster:
- EKS cluster with private and public endpoint access
- OIDC provider for IRSA
- EBS CSI driver add-on with dedicated IAM role
- ESO IRSA role for Secrets Manager access
- Cluster IAM role with required policies

### Node Group Module (`modules/node_group`)
Manages worker nodes:
- Managed node group with auto-scaling
- Instance type: t3a.medium (cost-optimized)
- 20GB EBS root volume per node
- IAM role with required node policies
- Scaling configuration: min 2, max 3, desired 3

## 🗄️ State Management

Terraform state is stored remotely in S3:
- **Bucket**: `max-terraform-s3`
- **Key**: `my-bookshelf/terraform.tfstate`
- **Region**: `ap-south-1`
- **Locking**: Enabled via S3

To use existing state:
```bash
terraform init -backend-config="bucket=max-terraform-s3" \
  -backend-config="key=my-bookshelf/terraform.tfstate" \
  -backend-config="region=ap-south-1"
```

## 🔄 GitOps Integration

This infrastructure sets up ArgoCD for GitOps-based deployments:

### ArgoCD Setup
1. **Helm Installation**: ArgoCD v8.0.10 in `argocd` namespace
2. **Repository Access**: SSH key from AWS Secrets Manager
3. **App of Apps**: Automatically deploys from `my-bookshelf-gitops` repo

### Repository Secret
The SSH key for GitLab access is:
- Stored in AWS Secrets Manager: `max-argocd-git-ssh-key`
- Automatically configured as Kubernetes secret: `repo-gitlab-ssh`
- Used by ArgoCD to access the GitOps repository

## 🔒 Security

### IAM Roles and Policies
- **Cluster Role**: Minimal permissions for EKS cluster operation
- **Node Role**: EC2, ECR, and CNI permissions for worker nodes
- **EBS CSI Role**: EBS volume management permissions
- **ESO Role**: Secrets Manager read access for specific secrets

### IRSA (IAM Roles for Service Accounts)
Configured for:
- `kube-system:ebs-csi-controller-sa` - EBS volume provisioning
- `external-secrets` service accounts in multiple namespaces
- Secrets access limited to `my-bookshelf/db-creds-*` pattern

### Network Security
- Nodes in private subnets (no direct internet access)
- NAT Gateway for secure outbound connections
- Security groups managed by EKS

## 💰 Cost Optimization

### Current Setup Costs (Configurable)
With default `terraform.tfvars` settings:
- **EKS Cluster**: ~$0.10/hour
- **EC2 Nodes**: 3 x t3a.medium (~$0.11/hour total)
- **NAT Gateway**: ~$0.045/hour + data transfer
- **Total**: ~$0.26/hour (~$190/month)

### Cost-Saving Configuration
Edit your `terraform.tfvars` for lower costs:
```hcl
# Reduce to ~$130/month
node_instance_type = "t3a.small"
node_desired_capacity = 2
node_max_capacity = 2
node_min_capacity = 1
```

### Cost Saving Tips
1. Use spot instances for non-critical workloads
2. Scale down node group during off-hours using your tfvars
3. Consider smaller instance types for dev/test environments
4. Remove NAT Gateway for isolated environments
5. Use the cost-saving configuration in your tfvars file

### Easy Cost Management
Since all settings are in `terraform.tfvars`, you can easily:
- Switch between cost-optimized and performance configurations
- Test different instance types without code changes
- Scale up/down based on current needs

## 🔗 Related Repositories

### my-bookshelf-app
- Main application repository
- Contains Flask backend and frontend code
- CI/CD pipeline pushes images to ECR

### my-bookshelf-gitops
- Kubernetes manifests and Helm charts
- ArgoCD application definitions
- Environment-specific configurations

## 🌐 Architecture Notes

### Frontend Delivery
While this repository manages backend infrastructure, the frontend is served through:
- **CloudFront CDN**: Manually created distribution
- **S3 Bucket**: Stores static frontend files
- **API Integration**: Frontend JavaScript routes API calls to the Kubernetes ingress

This separation allows for:
- Independent frontend deployments
- Global CDN caching for better performance
- Cost-effective static content delivery

## 🔧 Troubleshooting

### Common Issues

**EKS cluster not accessible:**
```bash
# Update kubeconfig (use your project name)
aws eks update-kubeconfig --region ap-south-1 --name {your-project}-eks

# Check cluster status
aws eks describe-cluster --name {your-project}-eks --region ap-south-1
```

**Variables not working:**
```bash
# Verify your tfvars file exists
ls -la terraform.tfvars

# Check variable validation
terraform validate

# See what values Terraform is using
terraform console
> var.project
> var.node_instance_type
```

**Want to change configuration:**
```bash
# Edit your variables
nano terraform.tfvars

# See what will change
terraform plan

# Apply changes
terraform apply
```

**ArgoCD not syncing:**
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Verify SSH secret
kubectl get secret repo-gitlab-ssh -n argocd -o jsonpath='{.data.sshPrivateKey}' | base64 -d

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-repo-server
```

**Nodes not joining cluster:**
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name max-my-bookshelf-eks \
  --nodegroup-name max-node-group --region ap-south-1

# View node logs
kubectl get nodes
kubectl describe node <node-name>
```

**Persistent volumes not working:**
```bash
# Verify EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi

# Check storage classes
kubectl get storageclass

# View CSI driver logs
kubectl logs -n kube-system deployment/ebs-csi-controller
```

### Destroy Infrastructure
To tear down all resources:
```bash
# Remove ArgoCD applications first
kubectl delete -n argocd application --all

# Destroy infrastructure
terraform destroy
```

⚠️ **Warning**: This will delete all resources including any data in persistent volumes.

---

**Maintainer:** Max Develeap  
**Email:** max@develeap.com  
**Repository:** [GitLab - my-bookshelf-infra](https://gitlab.com/maxopsdeveleap/my-bookshelf-infra)
