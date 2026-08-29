# oficina-infra-k8s

Infraestrutura como código (Terraform) para provisionar o cluster Kubernetes EKS na AWS, além dos manifestos Kubernetes da aplicação.

## Recursos provisionados

- **EKS Cluster** `oficina-cluster` — Kubernetes 1.30
- **Node Group** — 2 nós `t3.medium` (escalável de 1 a 4)
- **IAM Roles** — para o cluster e para os nós

## Estrutura

```
oficina-infra-k8s/
├── main.tf           ← EKS cluster, node group, IAM roles
├── variables.tf      ← region, tipo e quantidade de nós
├── outputs.tf        ← cluster name, endpoint, comando kubeconfig
└── k8s/
    ├── namespace.yaml
    ├── secret.yaml   ← credenciais (substituir PLACEHOLDERs antes de aplicar)
    ├── configmap.yaml
    ├── deployment.yaml
    ├── service.yaml  ← LoadBalancer expondo porta 80
    └── hpa.yaml      ← autoescala entre 2 e 6 réplicas
```

## Custo

> **Atenção:** EKS não tem free tier.
> - Cluster: ~$0.10/h (~$7/mês)
> - 2 nós `t3.medium`: ~$0.09/h cada (~$60/mês total)
>
> **Estratégia:** provisionar apenas para demonstração e destruir com `terraform destroy` logo após.

## Deploy (manual via GitHub Actions)

Actions → **Deploy Infraestrutura EKS** → Run workflow → selecione `apply` ou `destroy`

## Após o apply

```bash
# Configurar kubectl
aws eks update-kubeconfig --region sa-east-1 --name oficina-cluster

# Substituir PLACEHOLDERs no secret.yaml e aplicar manifestos
kubectl apply -f k8s/
```

## Secrets necessários no GitHub

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
