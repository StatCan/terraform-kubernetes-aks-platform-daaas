# AAD Pod Identity Configuration for Vault
resource "local_file" "vault_aad" {
  content = "${templatefile("${path.module}/config/vault/aad.yaml", {
    vault_aad_resource_id = "${var.vault_aad_resource_id}"
    vault_aad_client_id   = "${var.vault_aad_client_id}"
  })}"

  filename = "${path.module}/generated/vault/aad.yaml"
}

resource "null_resource" "vault_aad" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.vault_aad.filename}"
  }

  depends_on = [
    "module.helm_cert_manager"
  ]
}


module "helm_vault" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-vault.git"

  chart_version = "0.0.7"
  dependencies = [
    "${module.namespace_vault.depended_on}",
    "${null_resource.helm_repo_add.id}",
  ]

  helm_service_account = "tiller"
  helm_namespace       = "vault"
  helm_repository      = "statcan"

  values = <<EOF
vault:
  global:
    imagePullSecrets:
      - name: k8scc01covidacr-registry-connection

  injector:
    enabled: false

  server:
    image:
      repository: k8scc01covidacr.azurecr.io/vault
      tag: 1.4.0

    authDelegator:
      enabled: false

    ingress:
      enabled: true
      hosts:
        - host: vault.${var.ingress_domain}
          paths:
          - '/.*'
      annotations:
        kubernetes.io/ingress.class: istio

    dataStorage:
      enabled: false

    extraLabels:
      aadpodidbinding: vault

    standalone:
      config: |
        ui = true

        plugin_directory = "/plugins"

        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }

        seal "azurekeyvault" {
          tenant_id = "${var.vault_tenant_id}"
          vault_name = "k8scc01covid-vault"
          key_name = "vault"
        }

        storage "azure" {
          accountName = "k8scc01covidvaultdoonr"
          accountKey = "${var.vault_azure_storage_key}"
          container = "vault"
        }

destinationRule:
  enabled: false
EOF
}

# resource "null_resource" "vault_patches" {
#   triggers = {
#     revision = "${module.helm_vault.release_revision}"
#   }
#   provisioner "local-exec" {
#     command = "kubectl -n cloudops patch statefulset vault --type=json -p='[{\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/env/3/value\", \"value\": \"http://vault.vault.svc.cluster.local:8200\"}]'"
#   }
#   depends_on = [
#     "module.vault_patches"
#   ]
# }
