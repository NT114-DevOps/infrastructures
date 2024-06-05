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
  cluster_name = "microservice-cluster"
  vpc_id = "vpc-03312ce83615cf80a"
  subnet_ids = ["subnet-0930513f1b4fe91fc", "subnet-02732b19faaaf68e2"]
  iam_role_arn = "arn:aws:iam::624899937274:role/LabRole"
}

# EKS Cluster provisioning
resource "aws_eks_cluster" "microservice_cluster" {
  name     = local.cluster_name
  role_arn = local.iam_role_arn

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  version = "1.29" 
}

output "endpoint" {
  value = aws_eks_cluster.microservice_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.microservice_cluster.certificate_authority[0].data
}

# EKS Node Group
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = local.cluster_name
  node_group_name = "node-group"
  node_role_arn    = local.iam_role_arn
  subnet_ids       = local.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [ aws_eks_cluster.microservice_cluster ]
}

# EKS Add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name = local.cluster_name
  addon_name = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  depends_on = [ aws_eks_cluster.microservice_cluster, aws_eks_node_group.my_node_group ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = local.cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.microservice_cluster ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = local.cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.microservice_cluster ]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = local.cluster_name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.microservice_cluster ]
}