module "helm_istio" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-istio.git"

  chart_version = "1.4.7"
  dependencies = [
    "${module.namespace_istio_system.depended_on}",
  ]

  helm_service_account = "tiller"
  helm_namespace       = "${kubernetes_namespace.istio_system.metadata.0.name}"
  helm_repository      = "istio"

  values = <<EOF
# Use a specific image
global:
  # tag: release-1.1-latest-daily

  k8sIngress:
    enabled: true
    enableHttps: true

  controlPlanSecurityEnabled: true
  disablePolicyChecks: false
  policyCheckFailOpen: false
  enableTracing: false

  mtls:
    enabled: true

  outboundTrafficPolicy:
    mode: ALLOW_ANY

sidecarInjectorWebhook:
  enabled: true
  # If true, webhook or istioctl injector will rewrite PodSpec for liveness
  # health check to redirect request to sidecar. This makes liveness check work
  # even when mTLS is enabled.
  rewriteAppHTTPProbe: true

pilot:
  enableProtocolSniffingForInbound: false
  enableProtocolSniffingForOutbound: false
  autoscaleEnabled: true
  autoscaleMin: 2
  autoscaleMax: 5

galley:
  autoscaleEnabled: true
  autoscaleMin: 2
  autoscaleMax: 5

mixer:
  policy:
    autoscaleEnabled: true
    autoscaleMin: 2
    autoscaleMax: 5
  telemetry:
    autoscaleEnabled: true
    autoscaleMin: 2
    autoscaleMax: 5

gateways:
  istio-ingressgateway:
    sds:
      enabled: true
    autoscaleEnabled: true
    autoscaleMin: 2
    autoscaleMax: 5

security:
  replicaCount: 2

kiali:
  enabled: true
  contextPath: /
  ingress:
    enabled: true
    ## Used to create an Ingress record.
    hosts:
      - istio-kiali.${var.ingress_domain}
    annotations:
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
      kubernetes.io/ingress.class: "istio"
    tls:
      # Secrets must be manually created in the namespace.
      # - secretName: kiali-tls
      #   hosts:
      #     - kiali.local

  dashboard:
    grafanaURL: https://istio-grafana.${var.ingress_domain}

grafana:
  enabled: true
  contextPath: /
  ingress:
    enabled: true
    ## Used to create an Ingress record.
    hosts:
      - istio-grafana.${var.ingress_domain}
    annotations:
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
      kubernetes.io/ingress.class: "istio"
    tls:
      # Secrets must be manually created in the namespace.
      # - secretName: grafana-tls
      #   hosts:
      #     - grafana.local

prometheus:
  enabled: true
EOF
}

resource "null_resource" "add_https_to_ingress_gateway" {
  provisioner "local-exec" {
    command = "kubectl -n istio-system patch gateway istio-autogenerated-k8s-ingress --patch \"${file("${path.module}/config/istio/httpsredirect.yaml")}\""
  }

  provisioner "local-exec" {
    command = "kubectl -n istio-system patch gateway istio-autogenerated-k8s-ingress --patch \"${file("${path.module}/config/istio/sds.yaml")}\""
  }

  depends_on = [
    "module.helm_istio"
  ]
}
