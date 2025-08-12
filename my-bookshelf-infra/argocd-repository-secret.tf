# Data source to fetch the SSH key from AWS Secrets Manager
data "aws_secretsmanager_secret" "argocd_ssh_key" {
  name = "max-argocd-git-ssh-key"
}

data "aws_secretsmanager_secret_version" "argocd_ssh_key" {
  secret_id = data.aws_secretsmanager_secret.argocd_ssh_key.id
}

# Create Kubernetes secret for ArgoCD repository
resource "kubernetes_secret" "argocd_repo_ssh" {
  metadata {
    name      = "repo-gitlab-ssh"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = "git@gitlab.com:maxopsdeveleap/my-bookshelf-gitops.git"
    sshPrivateKey = jsondecode(data.aws_secretsmanager_secret_version.argocd_ssh_key.secret_string)["id_ed25519"]
  }

  type = "Opaque"

  depends_on = [helm_release.argocd]
}