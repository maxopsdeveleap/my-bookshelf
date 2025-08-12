# Only create the bookshelf-db namespace since it's needed by child chart
# All other namespaces are managed by ArgoCD with CreateNamespace=true

resource "kubernetes_namespace" "bookshelf_db" {
  metadata {
    name = "bookshelf-db"
  }
  depends_on = [module.eks]
}
