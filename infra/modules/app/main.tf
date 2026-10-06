locals {
  labels = {
    app        = var.app_name
    managed_by = "terraform"
  }
  container_port = 8080

  index_html = templatefile("${path.module}/templates/index.html.tftpl", {
    title    = var.page_title
    env      = var.env
    replicas = var.replicas
    image    = var.image
    owner    = var.owner
  })

  nginx_conf = templatefile("${path.module}/templates/default.conf.tftpl", {
    port = local.container_port
  })
}

# ---------- Namespace (department) ----------
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = var.namespace
    labels = local.labels
  }
}

# ---------- ConfigMap (web page + nginx config as data) ----------
resource "kubernetes_config_map_v1" "web" {
  metadata {
    name      = "${var.app_name}-content"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = local.labels
  }

  data = {
    "index.html"   = local.index_html
    "default.conf" = local.nginx_conf
  }
}

# ---------- Deployment (keeps N pods running) ----------
resource "kubernetes_deployment_v1" "this" {
  # checkov:skip=CKV_K8S_43:Image is pinned to an exact version tag; digest pinning planned via Renovate
  # checkov:skip=CKV_K8S_15:IfNotPresent is fine for pinned tags and works offline on kind
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
        annotations = {
          # Changes whenever the page or config changes -> triggers a rolling update
          "checksum/content" = sha256("${local.index_html}${local.nginx_conf}")
        }
      }

      spec {
        # Pod-level security: never run as root
        security_context {
          run_as_non_root = true
          run_as_user     = 101
          run_as_group    = 101
          fs_group        = 101
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = local.container_port
          }

          # Container-level security: least privilege
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            privileged                 = false
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = { cpu = "50m", memory = "32Mi" }
            limits   = { cpu = "200m", memory = "128Mi" }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = local.container_port
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = local.container_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            failure_threshold     = 3
          }

          # nginx needs a writable /tmp because the root filesystem is read-only
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          volume_mount {
            name       = "content"
            mount_path = "/usr/share/nginx/html/index.html"
            sub_path   = "index.html"
            read_only  = true
          }

          volume_mount {
            name       = "content"
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "default.conf"
            read_only  = true
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }

        volume {
          name = "content"
          config_map {
            name = kubernetes_config_map_v1.web.metadata[0].name
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
      target_port = local.container_port
    }
  }
}
