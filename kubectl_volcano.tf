# Volcano

resource "null_resource" "volcano" {
  provisioner "local-exec" {
    command = "kubectl apply -f '${path.module}/config/volcano/setup.yaml'"
  }
}
