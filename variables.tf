variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "eks_cluster_id" {
  description = "EKS Cluster Id - This cluster must exist."
  type        = string
}

variable "eks_cluster_oidc_issuer_url" {
  description = "URL to the oidc issuer. The cluster must have been created with :   oidc_provider_enabled = true"
  type        = string
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

variable "enable_ssl" {
  description = "Setup https for the daskhub cluster. Requires a domain named purchased on AWS with an ACM certificate"
  default     = false
}

variable "daskhub_values_files" {
  description = "Paths to additional values files to pass into the helm install command."
  type        = list(string)
  default     = []
}

variable "daskhub_values_upgrade_files" {
  description = "Paths to additional values files to pass into the helm upgrade command."
  type        = list(string)
  default     = []
}

variable "letsencrypt_email" {
  description = "Email to use for https setup."
  type        = string
  default     = ""
}

variable "daskhub_subdomain" {
  type        = string
  default     = "k8-jhub"
  description = "If enable_ssl = True : Subdomain to access your Jubyterhub cluster. {daskhub_subdomain}.{daskhub_domain}"
}

variable "daskhub_domain" {
  description = "Full domain name: example.com without the www/jhub/etc "
  type        = string
  default     = "example.com"
}


variable "zone_id" {
  type        = string
  description = "If enable_ssl = True : The zone id to use for your daskhub deployment"
  default     = "1243"
}

variable "daskhub_update_sleep" {
  type        = number
  default     = 300
  description = "Time to sleep when running the helm update to apply SSL. If this is the first time running it is strongly recommended to set a large wait time, or you will clobber your release."
}

variable "daskhub_helm_values_dir" {
  type        = string
  description = "Directory to store additional daskhub values files."
  default     = "helm_charts/daskhub"
}
