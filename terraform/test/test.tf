# Setup testing environment cluster
locals {
  cluster_name = "test-environment"
  node_group_name = "test-nodes"
  vpc_id = "vpc-03312ce83615cf80a"
  subnet_ids = ["subnet-0930513f1b4fe91fc", "subnet-02732b19faaaf68e2"]
  iam_role_arn = "arn:aws:iam::624899937274:role/LabRole"
}

# EKS Cluster provisioning
resource "aws_eks_cluster" "test_cluster" {
  name     = local.cluster_name
  role_arn = local.iam_role_arn

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  version = "1.29" 
}

output "endpoint" {
  value = aws_eks_cluster.test_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.test_cluster.certificate_authority[0].data
}

# EKS Node Group
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = local.cluster_name
  node_group_name = local.node_group_name
  node_role_arn    = local.iam_role_arn
  subnet_ids       = local.subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [ aws_eks_cluster.test_cluster ]
}

# EKS Add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name = local.cluster_name
  addon_name = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  depends_on = [ aws_eks_cluster.test_cluster, aws_eks_node_group.my_node_group ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = local.cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.test_cluster ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = local.cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.test_cluster ]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = local.cluster_name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  depends_on = [ aws_eks_cluster.test_cluster ]
}


# Prometheus and Grafana
resource "kubernetes_namespace" "prometheus-namespace" {
  depends_on = [aws_eks_node_group.my_node_group]

  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "prometheus" {
  depends_on = [ kubernetes_namespace.prometheus-namespace ]
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.prometheus-namespace.id
  create_namespace = true
  version    = "45.7.1"
  values = [
    file("values.yaml")
  ]
  timeout = 2000
  

set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = false
  }

  # You can provide a map of value using yamlencode. Don't forget to escape the last element after point in the name
  set {
    name = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}



# ArgoCD
# Create argocd namespace
resource "kubernetes_namespace" "argo-namespace" {
  depends_on = [aws_eks_node_group.my_node_group]

  metadata {
    name = "argocd"
  }
}

# Update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name my-eks-cluster"
  }
  depends_on = [kubernetes_namespace.argo-namespace]
}

# Install argocd
resource "null_resource" "argocd-install" {
  provisioner "local-exec" {
    command = "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
  }

  depends_on = [
    null_resource.update_kubeconfig
  ]
}

# Expose argocd server
resource "null_resource" "argocd-server" {
  provisioner "local-exec" {
    command = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
  }

  depends_on = [
    null_resource.argocd-install
  ]
}