terraform {
  required_version = ">= 1.1"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }

  backend "gcs" {}
}

provider "kubernetes" {
  config_path = var.kubeconfig_path != "" ? var.kubeconfig_path : null
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "name" {
  type = string
}

variable "value" {
  type = map(string)
}

variable "kubeconfig_path" {
  type    = string
  default = ""
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  type = "Opaque"
  data = var.value
}