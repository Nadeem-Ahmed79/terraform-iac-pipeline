locals {
  labels = {
    app        = var.app_name
    managed_by = "terraform"
  }
}

# ---------- Namespace (department) ----------
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = var.namespace
    labels = local.labels
  }
}

# ---------- Deployment (keeps N pods running) ----------
resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.app_name }
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = 80
          }

          resources {
            requests = { cpu = "50m", memory = "32Mi" }
            limits   = { cpu = "200m", memory = "128Mi" }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# ---------- Service (fixed address in front of pods) ----------
resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    selector = { app = var.app_name }
    type     = "ClusterIP"

    port {
      port        = 80
      target_port = 80
    }
  }
}
