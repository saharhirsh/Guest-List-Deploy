# kubernetes.tf
# Kubernetes resources for Guest List API deployment

# Namespace for the application
resource "kubernetes_namespace" "guestlist" {
  metadata {
    name = "guestlist-${var.environment}"
    labels = {
      environment = var.environment
      student     = var.student_name
    }
  }

  depends_on = [aws_eks_cluster.main, aws_eks_node_group.main]
}

# Deployment
resource "kubernetes_deployment" "guestlist_api" {
  metadata {
    name      = "guestlist-deployment"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
    labels = {
      app         = "guestlist-api"
      environment = var.environment
      student     = var.student_name
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "guestlist-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "guestlist-api"
        }
      }

      spec {
        container {
          image = var.app_image
          name  = "guestlist-container"

          port {
            container_port = 1111
            protocol       = "TCP"
          }

          # Health checks
          liveness_probe {
            http_get {
              path = "/"
              port = 1111
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 1111
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          # Resource limits for cost optimization
          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          # Environment variables (if needed)
          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }
        }
      }
    }
  }

  depends_on = [aws_eks_cluster.main, aws_eks_node_group.main]
}

# Service
resource "kubernetes_service" "guestlist_service" {
  metadata {
    name      = "guestlist-service"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
    labels = {
      app         = "guestlist-api"
      environment = var.environment
      student     = var.student_name
    }
  }

  spec {
    selector = {
      app = "guestlist-api"
    }

    port {
      name        = "http"
      port        = 9999
      target_port = 1111
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.guestlist_api]
}

# ConfigMap for application configuration (optional)
resource "kubernetes_config_map" "guestlist_config" {
  metadata {
    name      = "guestlist-config"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  data = {
    environment = var.environment
    log_level   = "INFO"
  }
}

# Horizontal Pod Autoscaler (optional for cost management)
resource "kubernetes_horizontal_pod_autoscaler_v2" "guestlist_hpa" {
  metadata {
    name      = "guestlist-hpa"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.guestlist_api.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
