locals {
  pg_labels = {
    app        = "postgres"
    managed_by = "terraform"
  }
}

# ---------- Namespace (database department) ----------
resource "kubernetes_namespace_v1" "data" {
  metadata {
    name   = var.namespace
    labels = { managed_by = "terraform" }
  }
}

# ---------- Kubernetes Secret (copied from the same random password) ----------
resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace_v1.data.metadata[0].name
  }

  data = {
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = random_password.db.result
    POSTGRES_DB       = var.db_name
  }
}

# ---------- Headless Service (stable DNS name) ----------
resource "kubernetes_service_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.data.metadata[0].name
    labels    = local.pg_labels
  }

  spec {
    cluster_ip = "None"
    selector   = { app = "postgres" }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

# ---------- StatefulSet (database with its own disk) ----------
resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.data.metadata[0].name
    labels    = local.pg_labels
  }

  spec {
    service_name = kubernetes_service_v1.postgres.metadata[0].name
    replicas     = 1

    selector {
      match_labels = { app = "postgres" }
    }

    template {
      metadata {
        labels = local.pg_labels
      }

      spec {
        container {
          name  = "postgres"
          image = var.image

          port {
            container_port = 5432
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.postgres.metadata[0].name
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }

          readiness_probe {
            exec {
              command = ["sh", "-c", "pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\""]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = { storage = var.storage_size }
        }
      }
    }
  }
}
