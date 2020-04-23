resource "kubernetes_deployment" "opa_minio" {
  metadata {
    name      = "opa"
    namespace = kubernetes_namespace.minio.metadata.0.name
    labels = {
      "app.kubernetes.io/name"     = "opa"
      "app.kubernetes.io/instance" = "minio"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "RollingUpdate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "minio"
        "app.kubernetes.io/instance" = "minio"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "minio"
          "app.kubernetes.io/instance" = "minio"
        }
      }

      spec {
        container {
          image = "openpolicyagent/opa:0.19.1"
          name  = "opa"

          args = [
            "run",
            "--ignore=.*",
            "--server",
            "/policies"
          ]

          port {
            name           = "http"
            container_port = 8181
          }

          volume_mount {
            name       = "policies"
            read_only  = true
            mount_path = "/policies"
          }

          liveness_probe {
            http_get {
              scheme = "HTTP"
              port   = 8181
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              scheme = "HTTP"
              port   = 8181
              path   = "/health?bundle=true"
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }

          resources {
            requests {
              cpu    = "10m"
              memory = "8Mi"
            }

            limits {
              cpu    = "10m"
              memory = "8Mi"
            }
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        volume {
          name = "policies"
          config_map {
            name = kubernetes_config_map.opa_minio.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "opa_minio" {
  metadata {
    name      = "opa"
    namespace = kubernetes_namespace.minio.metadata.0.name
    labels = {
      "app.kubernetes.io/name"     = "opa"
      "app.kubernetes.io/instance" = "minio"
    }
  }

  spec {
    type = "ClusterIP"
    selector = {
      "app.kubernetes.io/name"     = "opa"
      "app.kubernetes.io/instance" = "minio"
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 8181
      target_port = 8181
    }
  }
}

resource "kubernetes_config_map" "opa_minio" {
  metadata {
    name      = "opa-policies"
    namespace = kubernetes_namespace.minio.metadata.0.name
    labels = {
      "app.kubernetes.io/name"     = "opa"
      "app.kubernetes.io/instance" = "minio"
    }
  }

  data = {
    "policy.rego" = "${file("${path.module}/config/minio/policy.rego")}"
  }
}
