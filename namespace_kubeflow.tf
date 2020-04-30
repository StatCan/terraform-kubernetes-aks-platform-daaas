# kubeflow

resource "kubernetes_namespace" "kubeflow" {
  metadata {
    name = "kubeflow"
  }

  labels = {
    control-plane                      = "kubeflow"
    "katib-metricscollector-injection" = "enabled"
  }
}

module "namespace_kubeflow" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git"

  name = "${kubernetes_namespace.kubeflow.metadata.0.name}"
  namespace_admins = {
    users  = []
    groups = [var.kubernetes_rbac_group]
  }

  # ServiceAccount
  helm_service_account = "tiller"

  # CICD
  ci_name = "deploy"

  # Image Pull Secret
  enable_kubernetes_secret = "${var.enable_kubernetes_secret}"
  kubernetes_secret        = "${var.kubernetes_secret}"
  docker_repo              = "${var.docker_repo}"
  docker_username          = "${var.docker_username}"
  docker_password          = "${var.docker_password}"
  docker_email             = "${var.docker_email}"
  docker_auth              = "${var.docker_auth}"

  dependencies = []
}
