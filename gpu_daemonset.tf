resource "kubernetes_daemonset" "nvidia" {
  metadata {
    name      = "nvidia-gpu"
    namespace = "gpu-resources"
  }

  spec {
    strategy {
      type = "RollingUpdate"
    }

    selector {
      match_labels = {
        name = "nvidia-device-plugin-ds"
      }
    }

    template {
      metadata {
        annotations = {
          name = "scheduler.alpha.kubernetes.io/critical-pod"
        }
        labels = {
          name = "nvidia-device-plugin-ds"
        }
      }

      spec {
        container {
          image = "nvidia/k8s-device-plugin:1.11"
          name  = "nvidia-device-plugin-ctr"
          security_context {
            allow_privilege_escalation = "false"
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "device-plugin"
            mount_path = "nvidia-device-plugin-ctr"
          }
        }

        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }

        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
      }
    }
  }
}

