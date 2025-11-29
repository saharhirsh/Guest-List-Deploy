# variables.tf
# Environment variables for flexible deployment

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "guestlist-cluster"
}

variable "environment" {
  description = "Environment name (gili, sivan, sahar, dvir, dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small" # Cost-optimized
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2 # Minimal for cost
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "app_image" {
  description = "Docker image for the guest list application"
  type        = string
  default     = "giligalili/guestlistapi:ver04"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 3
}

variable "student_name" {
  description = "Student name for resource tagging"
  type        = string
  default     = "devsecops-student"
}
