############################################
# kubernetes.tf (EKS Fargate compatible)
# Kubernetes resources for Guest List API
############################################

############################################
# Namespace (must match Fargate profile selector)
############################################

resource "kubernetes_namespace_v1" "guestlist" {
  metadata {
    # IMPORTANT: Must match aws_eks_fargate_profile.guestlist selector namespace
    name = "guestlist"

    labels = {
      environment = var.environment
      student     = var.student_name
    }
  }

  # Ensure cluster + fargate profiles exist first
  depends_on = [
    aws_eks_cluster.main,
    aws_eks_fargate_profile.guestlist,
    aws_eks_fargate_profile.kube_system_coredns
  ]
}

############################################
# Deployment
############################################

resource "kubernetes_deployment_v1" "guestlist_api" {
  metadata {
    name      = "guestlist-deployment"
    namespace = kubernetes_namespace_v1.guestlist.metadata[0].name

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
          name  = "guestlist-container"
          image = var.app_image

          port {
            container_port = 1111
            protocol       = "TCP"
          }

          # Health checks (Flask serves '/' and '/health')
          liveness_probe {
            http_get {
              path = "/health"
              port = 1111
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 1111
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          # Resource requests/limits (Fargate uses these to size compute)
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

          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }
        }
      }
    }
  }

  depends_on = [
    aws_eks_fargate_profile.guestlist
  ]
}

############################################
# Service (LoadBalancer)
############################################

resource "kubernetes_service_v1" "guestlist_service" {
  metadata {
    name      = "guestlist-service"
    namespace = kubernetes_namespace_v1.guestlist.metadata[0].name

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

  depends_on = [
    kubernetes_deployment_v1.guestlist_api
  ]
}

############################################
# ConfigMap (optional)
############################################

resource "kubernetes_config_map_v1" "guestlist_config" {
  metadata {
    name      = "guestlist-config"
    namespace = kubernetes_namespace_v1.guestlist.metadata[0].name
  }

  data = {
    environment = var.environment
    log_level   = "INFO"
  }
}

############################################
# HPA (optional)
# NOTE: Requires metrics server in cluster. On EKS, you may need to install it.
# If you see errors about metrics, set enable_hpa=false and wrap this resource.
############################################

resource "kubernetes_horizontal_pod_autoscaler_v2" "guestlist_hpa" {
  metadata {
    name      = "guestlist-hpa"
    namespace = kubernetes_namespace_v1.guestlist.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.guestlist_api.metadata[0].name
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

  depends_on = [
    kubernetes_deployment_v1.guestlist_api
  ]
}
