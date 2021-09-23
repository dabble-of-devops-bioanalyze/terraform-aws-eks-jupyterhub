output "kubernetes_service-jhub-proxy-public_lb" {
  value = data.kubernetes_service.jhub.status.0.load_balancer.0.ingress.0.hostname
}

output "kubectl_update_command" {
  description = "Run this command to update the kubectl config"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_cluster_id}"
}

output "daskhub_values_upgrade" {
  value = local.daskhub_values_upgrade
}

output "daskhub_helm_upgrade_command" {
  description = "Helm upgrade command"
  value       = <<EOT
    helm repo add dask https://helm.dask.org/
    helm repo update
    # Wait a bit, sometimes the DNS record takes a few minutes to propogate
    echo "This command may take some time. Please wait and do not exit the screen"
    # sleep ${var.daskhub_update_sleep}
    helm upgrade --install ${var.daskhub_release_name} dask/daskhub \
     -n ${var.daskhub_namespace} \
      --values ${module.merged_values.helm_values_merged_file}
    EOT
}

output "merge_values" {
  value = module.merge_values
}

output "daskhub_values_update" {
  value = local.daskhub_values_upgrade
}
