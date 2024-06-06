# Setup production environment cluster



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
  cluster_name = "production-environment"
  node_group_name = "production-nodes"
  vpc_id = "vpc-03312ce83615cf80a"
  subnet_ids = ["subnet-0930513f1b4fe91fc", "subnet-02732b19faaaf68e2"]
  iam_role_arn = "arn:aws:iam::624899937274:role/LabRole"
}

# EKS Cluster provisioning
resource "aws_eks_cluster" "production_cluster" {
  name     = local.cluster_name
  role_arn = local.iam_role_arn

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  version = "1.29" 
}

output "endpoint" {
  value = aws_eks_cluster.production_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.production_cluster.certificate_authority[0].data
}

# EKS Node Group
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = local.cluster_name
  node_group_name = local.node_group_name
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

  depends_on = [ aws_eks_cluster.production_cluster ]
}


# EKS Add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name = local.cluster_name
  addon_name = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  depends_on = [ aws_eks_cluster.production_cluster, aws_eks_node_group.my_node_group ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = local.cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.production_cluster ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = local.cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.production_cluster ]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = local.cluster_name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.production_cluster ]
}

data "aws_eks_cluster" "production_cluster" {
  name = "production_cluster"
}

data "aws_eks_cluster_auth" "production_cluster" {
  name = "production_cluster"
}

# Configure the Kubernetes provider
provider "kubernetes" {
  host                   = aws_eks_cluster.production_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.production_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.production_cluster.token
}

# Install ArgoCD on the EKS cluster
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo/argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "4.9.6"

  values = [
    file("argocd-values.yaml")
  ]
}

# Expose the ArgoCD server using a LoadBalancer service
resource "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  spec {
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 8080
    }

    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
  }
}