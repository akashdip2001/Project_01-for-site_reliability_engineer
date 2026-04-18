# MyApp — Zero to Hero: Terraform, Kubernetes & CI/CD

> A complete learning repository. Follow every section in order to go from an empty machine to a fully deployed, production-grade application on AWS EKS Fargate.

---

## Architecture Overview

```
GitHub Actions (CI/CD)
  │  OIDC ──▶ AWS IAM Role
  │
  ├─▶ Build Docker images
  └─▶ Push to Amazon ECR
           │
  Terraform ──▶ Provisions VPC, EKS Fargate, ECR
           │
  kubectl  ──▶ Deploys manifests to EKS
           │
  ┌────────┴────────┐
  │  frontend:3000  │──▶│  backend:8000  │
  └─────────────────┘   └────────────────┘
```

---

## Prerequisites

| Tool | Install |
|------|---------|
| Git | `https://git-scm.com/downloads` |
| Docker | `https://docs.docker.com/get-docker/` |
| AWS CLI v2 | `https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html` |
| Terraform ≥ 1.5 | `https://developer.hashicorp.com/terraform/downloads` |
| kubectl | `https://kubernetes.io/docs/tasks/tools/` |
| Node.js 20+ | `https://nodejs.org/` |
| Python 3.12+ | `https://www.python.org/downloads/` |

---

## Phase 1 — Repository Initialization

```bash
# Clone or initialize the repo
git clone <your-repo-url> && cd myapp
# OR run the setup script on a fresh clone:
chmod +x repo-setup.sh && ./repo-setup.sh
```

**What this does:** Initializes git, formats Terraform files, installs a pre-commit hook that validates Terraform formatting and Python syntax on every commit, installs dependencies, and creates the initial commit.

---

## Phase 2 — Local Development & Docker

### Build images locally

```bash
# Build the backend image
docker build -t myapp-backend:local src/backend/
# Build the frontend image
docker build -t myapp-frontend:local src/frontend/
```

**What this does:** Each Dockerfile uses a slim/alpine base, installs only production dependencies, copies source code, and runs as a non-root user for security.

### Run locally with Docker

```bash
# Start backend
docker run -d --name backend -p 8000:8000 myapp-backend:local
# Start frontend, linking to backend
docker run -d --name frontend -p 3000:3000 \
  -e BACKEND_URL=http://host.docker.internal:8000 \
  myapp-frontend:local

# Test
curl http://localhost:8000/health    # {"status":"ok"}
curl http://localhost:3000/           # {"source":"frontend","backend_says":{...}}

# Cleanup
docker rm -f backend frontend
```

---

## Phase 3 — AWS & Terraform (Infrastructure)

### 3.1 Configure AWS CLI

```bash
# Configure your credentials (use SSO or IAM Identity Center for production)
aws configure
# Verify identity
aws sts get-caller-identity
```

### 3.2 Provision Infrastructure

```bash
cd terraform

# Initialize Terraform — downloads provider plugins
terraform init

# Preview what will be created (always review before applying)
terraform plan -out=tfplan

# Apply the plan — creates VPC, EKS, ECR, Fargate profile
terraform apply tfplan
```

| Command | What It Does |
|---------|-------------|
| `terraform init` | Downloads the AWS provider, initializes backend state |
| `terraform plan` | Dry-run showing every resource to be created/changed/destroyed |
| `terraform apply` | Executes the plan and provisions real AWS resources |
| `terraform destroy` | Tears down everything Terraform created (use when done) |

### 3.3 Key Resources Created

- **2 ECR Repositories** — `myapp-backend`, `myapp-frontend` (image scanning enabled, immutable tags)
- **VPC** — 2 public subnets, 2 private subnets, NAT Gateway, Internet Gateway
- **EKS Cluster** — Kubernetes 1.30, public + private API endpoint
- **Fargate Profile** — Runs pods in `default` namespace serverlessly (no EC2 nodes to manage)

---

## Phase 4 — Push Images to ECR

```bash
# Get your AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=eu-west-1

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Tag and push backend
docker tag myapp-backend:local $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/myapp-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/myapp-backend:latest

# Tag and push frontend
docker tag myapp-frontend:local $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/myapp-frontend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/myapp-frontend:latest
```

**What this does:** ECR is a private Docker registry. `get-login-password` generates a temporary 12-hour auth token — no static credentials stored.

---

## Phase 5 — Deploy to Kubernetes (EKS)

### 5.1 Connect kubectl to EKS

```bash
# Update your local kubeconfig to point at the new cluster
aws eks update-kubeconfig --name myapp-eks --region eu-west-1

# Verify connection
kubectl get nodes   # Fargate nodes appear only after pods are scheduled
kubectl cluster-info
```

**What this does:** Writes a context entry into `~/.kube/config` so kubectl knows how to authenticate to your EKS cluster using your AWS credentials.

### 5.2 Update Image References

Before applying, replace the placeholder image URIs in the Kubernetes manifests:

```bash
# Replace placeholders in manifests with your actual values
sed -i "s|<AWS_ACCOUNT_ID>|$AWS_ACCOUNT_ID|g" kubernetes/*.yaml
sed -i "s|<REGION>|$AWS_REGION|g" kubernetes/*.yaml
```

### 5.3 Apply Manifests

```bash
# Deploy backend and frontend
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/services.yaml

# Watch rollout status
kubectl rollout status deployment/backend
kubectl rollout status deployment/frontend

# Get the frontend LoadBalancer URL
kubectl get svc frontend-service
```

| Command | What It Does |
|---------|-------------|
| `kubectl apply -f <file>` | Creates or updates resources defined in the YAML |
| `kubectl get pods` | Lists running pods and their status |
| `kubectl get svc` | Lists services; shows the external LoadBalancer IP/DNS |
| `kubectl logs <pod>` | Streams logs from a specific pod |
| `kubectl describe pod <pod>` | Detailed info for debugging (events, conditions) |
| `kubectl rollout restart deployment/<name>` | Triggers a rolling restart with zero downtime |

---

## Phase 6 — CI/CD with GitHub Actions

### 6.1 Set Up OIDC in AWS

The pipeline uses **OIDC federation** — GitHub proves its identity to AWS without any stored secrets.

1. In the AWS Console → IAM → Identity Providers → **Add provider**
   - Provider type: `OpenID Connect`
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

2. Create an IAM Role with a trust policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {
         "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
       },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": {
           "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
         },
         "StringLike": {
           "token.actions.githubusercontent.com:sub": "repo:<GITHUB_ORG>/<REPO_NAME>:*"
         }
       }
     }]
   }
   ```

3. Attach policies: `AmazonEC2ContainerRegistryPowerUser`, `AmazonEKSClusterPolicy`

4. In GitHub → Repo Settings → Secrets → add `AWS_ROLE_ARN` with the role ARN.

### 6.2 Trigger the Pipeline

```bash
git add . && git commit -m "feat: initial deployment" && git push origin main
```

The pipeline will: checkout code → assume the IAM role via OIDC → log in to ECR → build & push both images → run `terraform fmt` check.

---

## Phase 7 — Teardown (Save Money!)

```bash
# Delete Kubernetes resources first
kubectl delete -f kubernetes/

# Destroy all Terraform-managed infrastructure
cd terraform && terraform destroy

# Verify nothing is left
aws eks list-clusters --region eu-west-1
aws ecr describe-repositories --region eu-west-1
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  INIT        git init && ./repo-setup.sh                │
│  BUILD       docker build -t img src/backend/           │
│  RUN LOCAL   docker run -p 8000:8000 img                │
│  INFRA UP    cd terraform && terraform init && apply    │
│  ECR LOGIN   aws ecr get-login-password | docker login  │
│  PUSH        docker push <ecr-url>/img:tag              │
│  K8S CONNECT aws eks update-kubeconfig --name cluster   │
│  DEPLOY      kubectl apply -f kubernetes/               │
│  STATUS      kubectl get pods,svc                       │
│  LOGS        kubectl logs -f deploy/backend             │
│  TEARDOWN    kubectl delete -f k8s/ && tf destroy       │
└─────────────────────────────────────────────────────────┘
```

---

## License

MIT
