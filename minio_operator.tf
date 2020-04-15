
# Minio

resource "null_resource" "minio" {
  provisioner "local-exec" {
    command = "kubectl apply -f '${path.module}/config/minio/minio-operator.yaml'"
  }
}
