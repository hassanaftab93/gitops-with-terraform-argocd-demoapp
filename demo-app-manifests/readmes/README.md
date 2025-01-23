# ArgoCD CLI Commands Guide

## 1. Login to ArgoCD

Login to your ArgoCD server using the CLI:

```bash
argocd login argocd.example.com --username admin --password mypassword
```

## 2. Project Management

### Create a New Project
```bash
argocd proj create my-project \
  --dest-cluster https://kubernetes.default.svc \
  --dest-namespace my-namespace \
  --src-repo https://github.com/my-org/my-repo.git
```

### List and View Projects
```bash
# List all projects
argocd proj list

# Get project details
argocd proj get my-project
```

## 3. Repository Management

### Add Repository with HTTPS Authentication
```bash
argocd repo add https://github.com/my-org/my-repo.git \
  --username git-user \
  --password git-password
```

### Add Repository with SSH Authentication
```bash
argocd repo add git@github.com:my-org/my-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

### List and Remove Repositories
```bash
# List repositories
argocd repo list

# Remove repository
argocd repo rm https://github.com/my-org/my-repo.git
```

## 4. Application Management

### Create Application
```bash
argocd app create my-application \
  --project my-project \
  --repo https://github.com/my-org/my-repo.git \
  --path k8s/manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace my-namespace \
  --sync-policy automated
```

### Application Operations
```bash
# List all applications
argocd app list

# Get application details
argocd app get my-application

# Refresh application status
argocd app get my-application --refresh

# Manual sync
argocd app sync my-application

# Delete application
argocd app delete my-application
```

## 5. Advanced Configuration Options

### Sync Policy Options
```bash
# Auto-prune resources
--sync-policy automated --auto-prune

# Enable self-healing
--sync-policy automated --self-heal

# Specify revision
--revision main

# Use custom values file
--values values-prod.yaml
```

## 6. Troubleshooting

### Debug Commands
```bash
# View application logs
argocd app logs my-application

# View application events
argocd app events my-application

# View application manifests
argocd app manifests my-application
```

## Important Notes

* Replace placeholder values (e.g., `argocd.example.com`, `my-project`, `my-organization`) with your actual values
* The `--sync-policy automated` flag enables automatic synchronization
* Use `--auto-prune` to automatically delete resources that are no longer defined in Git
* Use `--self-heal` to automatically correct drift between Git and live state