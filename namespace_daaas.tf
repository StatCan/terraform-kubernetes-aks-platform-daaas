# DAaaS
resource "kubernetes_namespace" "daaas" {
  metadata {
    name = "daaas"

    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}

module "namespace_daaas" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git"

  name = "${kubernetes_namespace.daaas.metadata.0.name}"
  namespace_admins = {
    users  = []
    groups = var.groups_daaas
  }

  # ServiceAccount
  helm_service_account = "tiller"

  # ServiceQuota Overrides
  allowed_loadbalancers = "10"
  allowed_nodeports     = "10"

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
