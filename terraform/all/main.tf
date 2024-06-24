# Setup test environment cluster

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  cluster_name = "test-environment"
  node_group_name = "test-nodes"
  prod_cluster_name = "production-environment"
  prod_node_group_name = "production-nodes"
  stage_cluster_name = "staging-environment"
  stage_node_group_name = "staging-nodes"
  vpc_id = "vpc-09c54b1cd895303e5"
  subnet_ids = ["subnet-03d59a663dd8b72e7", "subnet-0733a7a924b1effa4", "subnet-0d8bb5c00748ace13"]
  iam_role_arn = "arn:aws:iam::624899937274:role/LabRole"
}

# EKS Test Cluster provisioning
resource "aws_eks_cluster" "test_cluster" {
  name     = local.cluster_name
  role_arn = local.iam_role_arn

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  version = "1.29" 
}

# EKS Node Group
resource "aws_eks_node_group" "test_node_group" {
  cluster_name    = local.cluster_name
  node_group_name = local.node_group_name
  node_role_arn    = local.iam_role_arn
  subnet_ids       = local.subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [ aws_eks_cluster.test_cluster ]
}

output "endpoint1" {
  value = aws_eks_cluster.test_cluster.endpoint
}

output "kubeconfig-certificate-authority-data1" {
  value = aws_eks_cluster.test_cluster.certificate_authority[0].data
}


# EKS Add-ons
resource "aws_eks_addon" "coredns1" {
  cluster_name = local.cluster_name
  addon_name = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  depends_on = [ aws_eks_cluster.test_cluster, aws_eks_node_group.test_node_group ]
}

resource "aws_eks_addon" "kube-proxy1" {
  cluster_name = local.cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.test_cluster ]
}

resource "aws_eks_addon" "vpc-cni1" {
  cluster_name = local.cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.test_cluster ]
}

resource "aws_eks_addon" "eks-pod-identity-agent1" {
  cluster_name = local.cluster_name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.test_cluster ]
}


# EKS Cluster provisioning
resource "aws_eks_cluster" "production_cluster" {
  name     = local.prod_cluster_name
  role_arn = local.iam_role_arn

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  version = "1.29" 
}

output "endpoint2" {
  value = aws_eks_cluster.production_cluster.endpoint
}

output "kubeconfig-certificate-authority-data2" {
  value = aws_eks_cluster.production_cluster.certificate_authority[0].data
}

# EKS Node Group
resource "aws_eks_node_group" "prod_node_group" {
  cluster_name    = local.prod_cluster_name
  node_group_name = local.prod_node_group_name
  node_role_arn    = local.iam_role_arn
  subnet_ids       = local.subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [ aws_eks_cluster.production_cluster ]
}

# EKS Add-ons
resource "aws_eks_addon" "coredns2" {
  cluster_name = local.prod_cluster_name
  addon_name = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  depends_on = [ aws_eks_cluster.production_cluster, aws_eks_node_group.prod_node_group ]
}

resource "aws_eks_addon" "kube-proxy2" {
  cluster_name = local.prod_cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.production_cluster ]
}

resource "aws_eks_addon" "vpc-cni2" {
  cluster_name = local.prod_cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.production_cluster ]
}

resource "aws_eks_addon" "eks-pod-identity-agent2" {
  cluster_name = local.prod_cluster_name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.production_cluster ]
}



resource "aws_eks_cluster" "staging_cluster" {
  name     = local.stage_cluster_name
  role_arn = local.iam_role_arn

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  version = "1.29" 
}

# EKS Node Group
resource "aws_eks_node_group" "staging_node_group" {
  cluster_name    = local.stage_cluster_name
  node_group_name = local.stage_node_group_name
  node_role_arn    = local.iam_role_arn
  subnet_ids       = local.subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [ aws_eks_cluster.staging_cluster ]
}

output "endpoint3" {
  value = aws_eks_cluster.staging_cluster.endpoint
}

output "kubeconfig-certificate-authority-data3" {
  value = aws_eks_cluster.staging_cluster.certificate_authority[0].data
}


# EKS Add-ons
resource "aws_eks_addon" "coredns3" {
  cluster_name = local.stage_cluster_name
  addon_name = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  depends_on = [ aws_eks_cluster.staging_cluster, aws_eks_node_group.staging_node_group ]
}

resource "aws_eks_addon" "kube-proxy3" {
  cluster_name = local.stage_cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.staging_cluster ]
}

resource "aws_eks_addon" "vpc-cni3" {
  cluster_name = local.stage_cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.staging_cluster]
}

resource "aws_eks_addon" "eks-pod-identity-agent3" {
  cluster_name = local.stage_cluster_name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.staging_cluster ]
}