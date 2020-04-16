resource "kubernetes_daemonset" "sysctl" {
  metadata {
    name      = "sysctl"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "sysctl"
    }
  }

  spec {
    strategy {
      type = "RollingUpdate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "sysctl"
      }
    }

    template {
      metadata {
        annotations = {
          name = "scheduler.alpha.kubernetes.io/critical-pod"
        }
        labels = {
          "app.kubernetes.io/name" = "sysctl"
        }
      }

      spec {
        container {
          image = "busybox:latest"
          name  = "sysctl"

          command = [
            "/bin/sh",
            "-c",
            <<EOF
            set -o errexit
            set -o xtrace
            while sysctl -w vm.max_map_count=262144
            do
              sleep 60s
            done
            EOF
          ]

          security_context {
            privileged = "true"
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

        host_pid     = true
        host_ipc     = true
        host_network = true
        node_selector = {
          "kubernetes.io/os" = "linux"
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

        toleration {
          key      = "dedicated"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}
