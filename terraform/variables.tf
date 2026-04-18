variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}
