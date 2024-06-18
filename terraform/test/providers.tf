terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
     helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }

    kubernetes = {
        version = ">= 2.0.0"
        source = "hashicorp/kubernetes"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
    load_config_file = false
    host                   = aws_eks_cluster.test_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.test_cluster.certificate_authority[0].data)
    token                  = aws_eks_cluster.test_cluster.token
}

provider "kubectl" {
    load_config_file = false
    host                   = aws_eks_cluster.test_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.test_cluster.certificate_authority[0].data)
    token                  = aws_eks_cluster.test_cluster.token
}
