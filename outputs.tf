# outputs.tf
# Output values for the EKS deployment

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = false
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.main.status
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "load_balancer_ip" {
  description = "LoadBalancer Ingress IP for the guest list service"
  value       = kubernetes_service.guestlist_service.status[0].load_balancer[0].ingress[0].hostname
  depends_on  = [kubernetes_service.guestlist_service]
}

output "application_namespace" {
  description = "Kubernetes namespace where the application is deployed"
  value       = kubernetes_namespace.guestlist.metadata[0].name
}

output "kubectl_config" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}

# Cost estimation information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (approximate)"
  value = {
    "eks_cluster"    = "~$72.00 (24/7 control plane)"
    "t3_small_nodes" = "~$30.40 (2 nodes * ~$15.20/month each)"
    "nat_gateway"    = "~$32.40 (1 NAT gateway + data transfer)"
    "load_balancer"  = "~$16.20 (Classic Load Balancer)"
    "total_estimate" = "~$151.00/month"
    "note"           = "Costs vary by region and usage. Use AWS Cost Calculator for precise estimates."
  }
}
