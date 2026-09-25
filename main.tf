terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }
  required_version = ">= 1.1"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name = "app-secret"
  }
  type = "Opaque"
  data = {
    secret_msg = "hello-u85"
    api_key    = "test-api-key-abcdef"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "test-k8s-secret"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "test-k8s-secret" }
    }
    template {
      metadata {
        labels = { app = "test-k8s-secret" }
      }
      spec {
        container {
          name              = "app"
          image             = "localhost:5001/test-k8s-secret:latest"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 3000
          }
          env {
            name = "secret_msg"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "secret_msg"
              }
            }
          }
          env {
            name = "api_key"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "api_key"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "test-k8s-secret"
  }
  spec {
    type     = "NodePort"
    selector = { app = "test-k8s-secret" }
    port {
      port        = 3000
      target_port = 3000
      node_port   = 30080
    }
  }
}
