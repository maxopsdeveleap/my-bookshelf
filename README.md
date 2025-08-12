# My Bookshelf Project 📚

> A complete DevOps showcase project demonstrating modern cloud-native application deployment with AWS, Kubernetes, and GitOps best practices.

## 🌟 Project Overview

My Bookshelf is a full-stack web application for managing personal book collections, built to demonstrate enterprise-grade DevOps practices. This mother repository serves as the central hub for the three interconnected repositories that comprise the complete solution.

### 🎯 Key Highlights

- **Production-Ready Architecture**: Multi-tier application with separated frontend (CloudFront + S3) and backend (EKS)
- **Complete CI/CD Pipeline**: Automated testing, building, and deployment with Jenkins
- **GitOps Workflow**: Declarative infrastructure and application management with ArgoCD
- **Infrastructure as Code**: Fully automated AWS provisioning with Terraform
- **Enterprise Observability**: Integrated monitoring, logging, and code quality analysis

## 📦 Repository Structure

The My Bookshelf project consists of three repositories, each serving a specific purpose:

### 1. [my-bookshelf-app](https://gitlab.com/maxopsdeveleap/my-bookshelf-app)
**Purpose**: Main application source code and CI/CD pipeline
- Flask backend API with PostgreSQL
- Vanilla JavaScript frontend
- Docker containerization
- CI/CD pipelines (Jenkins & GitHub Actions)
- Automated testing (unit, integration, E2E)
- SonarQube integration

### 2. [my-bookshelf-infra](https://gitlab.com/maxopsdeveleap/my-bookshelf-infra)
**Purpose**: Infrastructure as Code (IaC) with Terraform
- AWS VPC with public/private subnets
- EKS cluster provisioning
- Node group management
- ArgoCD bootstrap
- IAM roles and policies
- External Secrets Operator setup
- **Terragrunt implementation** for multi-environment management

### 3. [my-bookshelf-gitops](https://gitlab.com/maxopsdeveleap/my-bookshelf-gitops)
**Purpose**: GitOps configurations and Kubernetes manifests
- ArgoCD App of Apps pattern
- Helm charts for application deployment
- External secrets management
- Monitoring stack (Prometheus, Grafana)
- Logging stack (EFK)
- Ingress and TLS configuration

## 🏗️ Architecture Overview

### Application Architecture

**Frontend Delivery**
- Static files hosted in S3 bucket
- CloudFront CDN for global distribution
- Direct API calls to backend via HTTPS

**Backend Services**
- Flask API running on EKS
- PostgreSQL database
- NGINX ingress controller
- SSL/TLS termination with cert-manager

**Infrastructure Components**
- VPC with 2 public and 2 private subnets
- EKS cluster with managed node groups
- NAT Gateway for outbound traffic
- Application Load Balancer

### DevOps Architecture

**CI/CD Flow**
1. Developer pushes code to GitLab/GitHub
2. CI/CD pipeline triggers (Jenkins or GitHub Actions)
3. Code quality analysis with SonarQube
4. Docker images built and tested
5. Images pushed to AWS ECR
6. GitOps repository updated with new version
7. ArgoCD syncs changes to Kubernetes

**GitOps Workflow**
- ArgoCD monitors GitOps repository
- Automatic synchronization of changes
- Self-healing infrastructure
- Rollback capabilities

## 🚀 Quick Start Guide

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.3.0
- kubectl >= 1.28
- Docker >= 20.10
- Git

### Deployment Steps

#### 1. Infrastructure Setup

**Option A: Standard Terraform**
```bash
# Clone infrastructure repository
git clone https://gitlab.com/maxopsdeveleap/my-bookshelf-infra.git
cd my-bookshelf-infra

# Initialize and apply Terraform
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name max-my-bookshelf-eks
```

**Option B: Terragrunt (Multi-Environment)**
```bash
# Clone infrastructure repository
git clone https://gitlab.com/maxopsdeveleap/my-bookshelf-infra.git
cd my-bookshelf-infra/terragrunt/environments/prod

# Deploy all modules
terragrunt run-all apply

# Or deploy specific modules
cd vpc && terragrunt apply
cd ../eks && terragrunt apply
cd ../node-group && terragrunt apply
cd ../argocd && terragrunt apply
```

#### 2. Create Required Secrets
```bash
# Database credentials
aws secretsmanager create-secret \
  --name my-bookshelf/db-creds \
  --secret-string '{
    "POSTGRES_USER":"postgres",
    "POSTGRES_PASSWORD":"your-secure-password",
    "POSTGRES_DB":"books"
  }'

# GitLab SSH key (if not already exists)
aws secretsmanager create-secret \
  --name max-argocd-git-ssh-key \
  --secret-string "$(cat ~/.ssh/id_rsa)"
```

#### 3. Verify ArgoCD Installation
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI (optional)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### 4. Deploy Applications
The App of Apps pattern automatically deploys all applications. To manually trigger:
```bash
kubectl apply -f https://gitlab.com/maxopsdeveleap/my-bookshelf-gitops/-/raw/main/apps/app-of-apps.yaml
```

#### 5. Access the Application
- **Production**: https://d29uf7fg4cztcx.cloudfront.net
- **API Endpoint**: https://mybookshelf.ddns.net

## 📊 Project Statistics

### Infrastructure Costs (Estimated)
- **EKS Cluster**: ~$0.10/hour
- **EC2 Nodes**: 3 x t3a.medium (~$0.11/hour)
- **NAT Gateway**: ~$0.045/hour + data transfer
- **Total**: ~$0.26/hour (~$190/month)

### Technology Stack
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend**: Python 3.9, Flask, SQLAlchemy
- **Database**: PostgreSQL 15
- **Container**: Docker, Kubernetes (EKS)
- **CI/CD**: Jenkins, ArgoCD
- **IaC**: Terraform
- **Monitoring**: Prometheus, Grafana, EFK Stack
- **Cloud**: AWS (EKS, ECR, S3, CloudFront, Secrets Manager)

## 🔄 Development Workflow

### Local Development
1. Clone the application repository
2. Use Docker Compose for local testing
3. Run unit, integration, and E2E tests
4. Push changes to feature branch

### CI/CD Pipeline
1. Jenkins runs automated tests
2. SonarQube analyzes code quality
3. Docker images built and tagged
4. Images pushed to ECR
5. GitOps repository updated

### Deployment
1. ArgoCD detects GitOps changes
2. Syncs new version to Kubernetes
3. Automated health checks
4. Rollback on failure

## 📈 Monitoring and Observability

### Metrics (Prometheus + Grafana)
- Application metrics (requests, latency)
- Kubernetes cluster metrics
- Custom business metrics

### Logging (EFK Stack)
- Centralized log collection
- Structured JSON logging
- Log retention and search

### Code Quality (SonarQube)
- Automated code analysis
- Security vulnerability detection
- Technical debt tracking

## 🛡️ Security Features

- **Secret Management**: AWS Secrets Manager with External Secrets Operator
- **Network Security**: Private subnets for workloads
- **IAM Roles**: Least privilege access with IRSA
- **TLS/SSL**: Automated certificate management
- **Container Security**: Regular base image updates

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the appropriate repository
2. Create a feature branch
3. Write tests for new features
4. Ensure all tests pass
5. Submit a pull request

### Commit Convention
- `MAJOR:` Breaking changes
- `MINOR:` New features
- No prefix: Bug fixes

## 📚 Documentation

Each repository contains detailed documentation:
- **Application**: API reference, testing guide
- **Infrastructure**: Terraform modules, AWS resources
- **GitOps**: Deployment strategies, troubleshooting

## 🔧 Troubleshooting

### Common Issues

**Application not accessible**
- Check ingress configuration
- Verify DNS settings
- Review TLS certificates

**Deployment failures**
- Check ArgoCD application status
- Review pod logs
- Verify secret availability

**Infrastructure issues**
- Check AWS resource limits
- Review Terraform state
- Verify IAM permissions

## 📞 Support

**Maintainer**: Max Develeap  
**Email**: max@develeap.com  
**GitLab**: [@maxopsdeveleap](https://gitlab.com/maxopsdeveleap)

## 📄 License

This project is part of a DevOps training program and is intended for educational purposes.

---

### 🎓 Learning Resources

This project demonstrates:
- Microservices architecture
- Container orchestration
- Infrastructure as Code
- GitOps methodology
- CI/CD best practices
- Cloud-native development
- Production monitoring

Perfect for learning modern DevOps practices in a real-world context!
