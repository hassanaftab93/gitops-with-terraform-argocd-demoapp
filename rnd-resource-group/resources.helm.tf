module "ingress_nginx" {
  source = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/helm/helm_release"

  chart            = "ingress-nginx"
  name             = "ingress-nginx"
  create_namespace = true
  namespace        = "ingress-nginx"
  values = [
    <<-EOF
    controller:
      service:
        type: LoadBalancer
    EOF
  ]
  repository = "https://kubernetes.github.io/ingress-nginx"
  providers = {
    helm = helm.helmk8s
  }
  depends_on = [data.azurerm_kubernetes_cluster.cluster, module.kubernetes]
}

module "argocd" {
  source = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/helm/helm_release"

  chart            = "argo-cd"
  name             = "argocd"
  create_namespace = true
  namespace        = "argocd"
  values = [
    <<-EOF
    server:
      service:
        type: ClusterIP
      configs:
        params:
          "server.insecure": "true"
    admin:
        username: admin
    EOF
  ]
  repository = "https://argoproj.github.io/argo-helm"
  providers = {
    helm = helm.helmk8s
  }
  depends_on = [data.azurerm_kubernetes_cluster.cluster, module.kubernetes]
}

# Get Initial Password
# username: admin
# kubectl patch secret argocd-secret -n argocd -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
# kubectl delete pods -n argocd -l app.kubernetes.io/name=argocd-server
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Update RBAC policy
# kubectl -n argocd edit configmap argocd-rbac-cm

# Add the following to the policy.csv section
# policy.csv: |
# p, role:admin, applications, *, *, *
# policy.default: role:admin

# Restart ArgoCD
# kubectl -n argocd rollout restart deployment argocd-server

# Login
# kubectl port-forward service/argocd-server -n argocd 8888:443
# argocd login 127.0.0.1:8888 --username admin --password <password>