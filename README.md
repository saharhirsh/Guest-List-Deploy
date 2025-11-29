# Guest List Deployment

This project provides an automated deployment of the Guest List application on AWS using Terraform and Kubernetes (EKS).  
It includes networking, security, managed Kubernetes cluster, and deployment of the Guest List API.

---

## Project Structure

- *GitHub Actions Workflow*  
  CI/CD pipeline for running Terraform against AWS. Manages creation, updates, and destruction of environments (dev, staging, prod), performs health checks, and generates kubeconfig for cluster access.

- *backend.tf*  
  Defines the Terraform backend. Stores state in S3 with locking in DynamoDB, separated by workspaces.

- *main.tf*  
  Provisions networking: VPC, public and private subnets, Internet Gateway, NAT Gateway, Route Tables, and Security Groups.

- *eks.tf*  
  Creates or references IAM Roles, provisions the EKS Cluster and Node Group, and configures the Kubernetes Provider.

- *kubernetes.tf*  
  Deploys the Guest List API to EKS: dedicated Namespace, Deployment with health checks and resource limits, Service of type LoadBalancer, ConfigMap, and Horizontal Pod Autoscaler.

- *state-bucket.tf*  
  (Optional) Provisions an S3 bucket for Terraform state with versioning, encryption, public access blocking, and lifecycle rules for archival.

- *variables.tf*  
  Input variables for flexible configuration: region, cluster name, environment, VPC CIDR, node type and size, application Docker image, replicas, and tagging.

- *outputs.tf*  
  Provides important outputs after deployment: cluster endpoint, Kubernetes version, VPC and subnet IDs, Load Balancer address, application namespace, kubeconfig command, and an estimated monthly cost.

---

## Prerequisites

- Active AWS account with appropriate permissions.
- Terraform installed (version >= 1.0.0 and < 1.10
