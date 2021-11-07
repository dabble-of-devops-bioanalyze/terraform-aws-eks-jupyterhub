data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_id
}

resource "null_resource" "kubectl_update" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks --region $AWS_REGION update-kubeconfig --name $NAME"
    environment = {
      AWS_REGION = var.region
      NAME       = var.eks_cluster_id
    }
  }
}

resource "null_resource" "proxy_secret" {
  depends_on = [
    null_resource.kubectl_update,
  ]

  provisioner "local-exec" {
    command = "openssl rand -hex 32 > ${var.daskhub_helm_values_dir}/PROXY_SECRET"
  }
}

resource "null_resource" "gateway_secret" {
  depends_on = [
    null_resource.proxy_secret
  ]

  provisioner "local-exec" {
    command = "openssl rand -hex 32 > ${var.daskhub_helm_values_dir}/GATEWAY_SECRET"
  }
}

data "local_file" "proxy_secret" {
  depends_on = [
    null_resource.proxy_secret
  ]
  filename = "${var.daskhub_helm_values_dir}/PROXY_SECRET"
}

data "local_file" "gateway_secret" {
  depends_on = [
    null_resource.gateway_secret
  ]
  filename = "${var.daskhub_helm_values_dir}/GATEWAY_SECRET"
}

data "template_file" "secrets" {
  depends_on = [
    data.local_file.proxy_secret,
    data.local_file.gateway_secret
  ]
  template = file("${path.module}/helm_charts/daskhub/secrets.yaml.tpl")
  vars = {
    proxy_secret   = chomp(data.local_file.proxy_secret.content)
    gateway_secret = chomp(data.local_file.gateway_secret.content)
  }
}

resource "local_file" "rendered_secret" {
  depends_on = [
    data.template_file.secrets
  ]
  content  = data.template_file.secrets.rendered
  filename = "${var.daskhub_helm_values_dir}/secrets.yaml"
}

resource "helm_release" "jhub" {
  depends_on = [
    null_resource.kubectl_update,
    local_file.rendered_secret,
  ]
  name             = var.daskhub_release_name
  repository       = "https://helm.dask.org"
  chart            = "daskhub"
  version          = var.daskhub_version
  namespace        = var.daskhub_namespace
  create_namespace = true
  wait             = true

  values = flatten([
    [
      [
        data.template_file.secrets.rendered
      ], [for s in var.daskhub_values_files : file(s)]
    ]
  ])
}

data "kubernetes_service" "jhub" {
  depends_on = [
    helm_release.jhub,
  ]
  metadata {
    name      = "proxy-public"
    namespace = var.daskhub_namespace
  }
}

# We need an A Record for the User Pool
data "aws_elb" "jhub" {
  depends_on = [
    helm_release.jhub,
    data.kubernetes_service.jhub
  ]
  name = split("-", data.kubernetes_service.jhub.status.0.load_balancer.0.ingress.0.hostname)[0]
}

data "template_file" "https" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    helm_release.jhub,
  ]
  template = file("${path.module}/helm_charts/daskhub/https.yaml.tpl")
  vars = {
    daskhub_domain    = var.daskhub_domain
    daskhub_subdomain = var.daskhub_subdomain
    letsencrypt_email = var.letsencrypt_email
  }
}

resource "local_file" "rendered_https" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    data.template_file.https[0]
  ]
  content  = data.template_file.https[0].rendered
  filename = "${var.daskhub_helm_values_dir}/https.yaml"
}

resource "aws_route53_record" "jhub" {
  count = var.enable_ssl ? 1 : 0
  depends_on = [
    helm_release.jhub,
    local_file.rendered_https,
    data.kubernetes_service.jhub,
    data.aws_elb.jhub,
  ]
  zone_id = var.zone_id
  name    = var.daskhub_subdomain
  type    = "A"
  alias {
    name                   = data.aws_elb.jhub.dns_name
    zone_id                = data.aws_elb.jhub.zone_id
    evaluate_target_health = true
  }
}

locals {
  daskhub_values_upgrade = tolist(distinct(
    compact(flatten([
      [
        [
          abspath(local_file.rendered_https[0].filename)
        ],
        [for s in var.daskhub_values_files : abspath(s)],
        [for s in var.daskhub_values_upgrade_files : abspath(s)]
      ]
    ]))
  ))
}

module "merge_values" {
  source            = "dabble-of-devops-biodeploy/merge-values/helm"
  version           = "0.0.1"
  context           = module.this.context
  helm_values_dir   = var.daskhub_helm_values_dir
  helm_values_files = local.daskhub_values_upgrade
}

resource "null_resource" "jhub_release_update" {
  count = var.enable_ssl ? 1 : 0
  depends_on = [
    helm_release.jhub,
    aws_route53_record.jhub,
    module.merge_values
  ]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOT
    helm repo add dask https://helm.dask.org/
    helm repo update
    # Wait a bit, sometimes the DNS record takes a few minutes to propogate
    echo "This command may take some time. Please wait and do not exit the screen"
    sleep ${var.daskhub_update_sleep}
    helm upgrade --install ${var.daskhub_release_name} dask/daskhub \
    --version ${var.daskhub_version} \
     -n ${var.daskhub_namespace} \
      --values ${module.merge_values.helm_values_merged_file}
    EOT
    environment = {
      AWS_REGION = var.region
    }
  }
}
