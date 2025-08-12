resource "kubectl_manifest" "app_of_apps" {
  yaml_body = file("../my-bookshelf-gitops/apps/app-of-apps.yaml")
  
  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_repo_ssh
  ]
}
