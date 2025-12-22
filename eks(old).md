variable "manage_iam" {
  description = "Whether to let Terraform manage IAM roles"
  type        = bool
  default     = false
}

variable "cluster_role_name" {
  type = string
}

variable "node_group_role_name" {
  type = string
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "cluster" {
  count = var.manage_iam ? 1 : 0
  name  = var.cluster_role_name

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
    Version = "2012-10-17"
  })

  tags = {
    Environment = var.environment
    Student     = var.student_name
  }
}

data "aws_iam_role" "cluster" {
  count = var.manage_iam ? 0 : 1
  name  = var.cluster_role_name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "nodes" {
  count = var.manage_iam ? 1 : 0
  name  = var.node_group_role_name

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
    Version = "2012-10-17"
  })

  tags = {
    Environment = var.environment
    Student     = var.student_name
  }
}

data "aws_iam_role" "nodes" {
  count = var.manage_iam ? 0 : 1
  name  = var.node_group_role_name
}

# Role ARNs בהתאם ל-manage_iam
locals {
  cluster_role_arn = var.manage_iam ? aws_iam_role.cluster[0].arn : data.aws_iam_role.cluster[0].arn
  nodes_role_arn   = var.manage_iam ? aws_iam_role.nodes[0].arn   : data.aws_iam_role.nodes[0].arn
}

# Attachments (רק אם Terraform יוצר את ה-roles)
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count      = var.manage_iam ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  count      = var.manage_iam ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes[0].name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  count      = var.manage_iam ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes[0].name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  count      = var.manage_iam ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes[0].name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = local.cluster_role_arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

  tags = {
    Environment = var.environment
    Student     = var.student_name
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = local.nodes_role_arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
instance_types = ["t3.micro"]

scaling_config {
  desired_size = 1
  max_size     = 1
  min_size     = 1
}

  update_config { max_unavailable = 1 }
  ami_type = "AL2_x86_64"

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Environment = var.environment
    Student     = var.student_name
  }
}

# Providers
data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}
