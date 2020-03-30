
# DataBricks Operator

resource "kubernetes_secret" "secret_registry" {
  metadata {
    name      = "dbrickssettings"
    namespace = "${kubernetes_namespace.databricks.metadata.0.name}"
  }

  data = {
    DatabricksHost  = "${var.databricks_host}"
    DatabricksToken = "${var.databricks_token}"
  }
}

resource "local_file" "databricks" {
  filename = "${path.module}/config/databricks/setup.yaml"
}

resource "null_resource" "databricks" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.databricks.filename}"
  }
}
