resource "kubernetes_namespace" "kijani_staging" {
  metadata {
    name = "kijani-staging"

    labels = {
      environment = "staging"
      application = "kijanikiiosk"
      managed-by  = "terraform"
    }
  }
}
