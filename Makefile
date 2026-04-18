.PHONY: help build run stop push infra-init infra-plan infra-apply infra-destroy deploy clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ── Local Development ──────────────────────────────
build: ## Build all Docker images locally
	docker compose build

run: ## Start all services locally
	docker compose up -d

stop: ## Stop all local services
	docker compose down

logs: ## Tail logs from all services
	docker compose logs -f

# ── ECR Push ───────────────────────────────────────
ecr-login: ## Authenticate Docker to ECR
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

push: ecr-login ## Tag and push images to ECR
	docker tag myapp-backend:local $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/myapp-backend:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/myapp-backend:latest
	docker tag myapp-frontend:local $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/myapp-frontend:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/myapp-frontend:latest

# ── Terraform ──────────────────────────────────────
infra-init: ## Initialize Terraform
	cd terraform && terraform init

infra-plan: ## Preview infrastructure changes
	cd terraform && terraform plan -out=tfplan

infra-apply: ## Apply infrastructure changes
	cd terraform && terraform apply tfplan

infra-destroy: ## Destroy all infrastructure
	cd terraform && terraform destroy

# ── Kubernetes ─────────────────────────────────────
deploy: ## Deploy manifests to EKS
	kubectl apply -f kubernetes/

status: ## Show pod and service status
	kubectl get pods,svc

undeploy: ## Remove all Kubernetes resources
	kubectl delete -f kubernetes/

# ── Cleanup ────────────────────────────────────────
clean: stop ## Stop containers and prune Docker
	docker system prune -f
