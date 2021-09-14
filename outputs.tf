output "kubernetes_service-jhub-proxy-public_lb" {
  value = data.kubernetes_service.jhub.status.0.load_balancer.0.ingress.0.hostname
}

output "kubectl_update_command" {
  description = "Run this command to update the kubectl config"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_cluster_id}"
}

output "daskhub_values" {
  description = "Values files passed to the daskhub helm chart"
  value = [
    abspath("${path.module}/helm_charts/daskhub/secrets.yaml"),
  ]
}
