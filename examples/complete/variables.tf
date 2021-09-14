variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

####################################################################
# EKS Node Groups 
####################################################################

# t3a.medium, t3a.large, t3a.2xlarge, m4.10xlarge

variable "eks_node_groups" {
  type = list(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    name           = string
  }))
  description = "EKS Node Groups"
  default = [
    {
      name           = "worker-group-1"
      instance_types = ["t3a.medium", "t3a.large", "t3a.2xlarge", "m4.10xlarge"]
      desired_size   = 1
      min_size       = 1
      max_size       = 450
      disk_size      = 50
    }
  ]
}

variable "zone_id" {
  type        = string
  description = "Zone ID For Route53 hosted"
}

variable "daskhub_subdomain" {
  type        = string
  default     = "k8-jhub"
  description = "Subdomain to access your Jubyterhub cluster."
}

variable "daskhub_domain" {
  type        = string
  default     = "example.com"
  description = "Route53 domain to access your Jubyterhub cluster."
}

variable "daskhub_namespace" {
  type        = string
  description = "K8s namespace for the daskhub chart"
  default     = "default"
}

variable "daskhub_version" {
  type    = string
  default = "2021.8.0"
}

variable "daskhub_release_name" {
  type        = string
  description = "Helm release name for the daskhub chart"
  default     = "jhub"
}

variable "daskhub_helm_values_dir" {
  type        = string
  description = "Directory to store additional daskhub values files. Relative to the directory where you run terraform apply. It is recommended to supply an absolute file path."
  default     = "helm_charts/daskhub"
}
