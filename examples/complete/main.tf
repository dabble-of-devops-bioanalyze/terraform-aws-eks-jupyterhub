provider "aws" {
  region = var.region
}

module "jhub" {
  source = "dabble-of-devops-biodeploy/eks-autoscaling/aws"
  # make sure to pin a version!
  # version = "1.10.0"

  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  oidc_provider_enabled             = true
  cluster_encryption_config_enabled = true
  # eks_worker_groups                 = var.eks_worker_groups
  eks_node_groups = var.eks_node_groups

  eks_node_group_autoscaling_enabled            = true
  eks_worker_group_autoscaling_policies_enabled = true

  context = module.this.context
}

data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.jhub.eks_cluster_id
    kubernetes_config_map_id = module.jhub.eks_cluster.kubernetes_config_map_id
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.jhub.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.jhub.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.jhub.eks_cluster_id]
      command     = "aws"
    }
  }
}

resource "null_resource" "kubectl_update" {
  depends_on = [
    module.jhub,
  ]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks --region $AWS_REGION update-kubeconfig --name $NAME"
    environment = {
      AWS_REGION = var.region
      NAME       = module.jhub.eks_cluster_id
    }
  }
}

resource "null_resource" "helm_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${var.daskhub_helm_values_dir}"
  }
}

locals {
  daskhub_helm_values_dir = abspath(var.daskhub_helm_values_dir)
}

locals {
  daskhub_values_upgrade_files = [
    abspath("../helm_charts/daskhub/auth.yaml"),
    abspath("${local.daskhub_helm_values_dir}/config.yaml"),
    abspath("${local.daskhub_helm_values_dir}/cellxgene.yaml"),
    abspath("${local.daskhub_helm_values_dir}/https.yaml"),
    abspath("${local.daskhub_helm_values_dir}/secrets.yaml"),
  ]
}

module "jhub_helm_release" {
  depends_on = [
    module.jhub,
  ]
  providers = {
    aws        = aws
    kubernetes = kubernetes
    helm       = helm
  }
  source                       = "dabble-of-devops-biodeploy/eks-jupyterhub/aws"
  region                       = var.region
  eks_cluster_id               = module.jhub.eks_cluster_id
  eks_cluster_oidc_issuer_url  = module.jhub.eks_cluster_identity_oidc_issuer
  daskhub_namespace            = var.daskhub_namespace
  enable_ssl                   = true
  daskhub_release_name         = var.daskhub_release_name
  daskhub_subdomain            = var.daskhub_subdomain
  letsencrypt_email            = "hello@myemail.com"
  daskhub_domain               = var.daskhub_domain
  daskhub_helm_values_dir      = local.daskhub_helm_values_dir
  zone_id                      = var.zone_id
  daskhub_values_upgrade_files = local.daskhub_values_upgrade_files
}
