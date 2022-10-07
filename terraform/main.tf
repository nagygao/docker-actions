terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.14.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "config"
  config_context = "kubernetes-admin@kubernetes"
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = "ns-terraform"
  }
}

resource "kubernetes_secret_v1" "dockerconfig" {
  metadata {
    name      = "docker-cfg"
    namespace = kubernetes_namespace.ns.id
  }

  data = {
    ".dockerconfigjson" = "ewogICJhdXRocyI6IHsKICAgICJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOiB7CiAgICAgICJhdXRoIjogImJtRm5lV2RoYnpwVGNuUkJNMGhxTmpVbCIKICAgIH0KICB9Cn0="
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_deployment_v1" "deployment" {
  metadata {
    name = "terraform-nginx"
    labels = {
      app = "terraform-nginx"
    }
    namespace = kubernetes_namespace.ns.id
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "terraform-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "terraform-nginx"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret_v1.dockerconfig.name
        }
        container {
          image = "nagygao/github-test:test"
          name  = "nginx"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }


          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "service" {
  metadata {
    name      = "svc-terraform-nginx"
    namespace = kubernetes_namespace.ns.id
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.deployment.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port = 31245
      port      = 80
    }
  }
}