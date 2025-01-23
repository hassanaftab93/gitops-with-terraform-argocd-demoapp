# ArgoCD CLI Commands for Azure DevOps Setup

## 1. Add Repository with SSH Authentication

Add the Azure DevOps repository to ArgoCD using the SSH URL:

```bash
    argocd repo add git@ssh.dev.azure.com:v3/myteo/Cloud/demo-app-manifests \
    --ssh-private-key-path ~/.ssh/id_azure \
    --upsert
```

## 2. Create Project: demo-app-project

Create a new ArgoCD project named demo-app-project:

```bash
    argocd proj create demo-app-project \
    --dest https://kubernetes.default.svc,* \
    --description "demo app project" \
    --src git@ssh.dev.azure.com:v3/myteo/Cloud/demo-app-manifests \
    --upsert
```

## 3. Create Application: demo-app-microservice1

Create a new application named demo-app-microservice1 linked to the repository and project:

```bash
    argocd app create demo-app-microservice1 \
    --project demo-app-project \
    --repo git@ssh.dev.azure.com:v3/myteo/Cloud/demo-app-manifests \
    --path manifests/main/demo-app \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default \
    --sync-policy automated \
    --auto-prune \
    --self-heal \
    --revision main \
    --upsert
```