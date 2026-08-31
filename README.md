# oficina-infra-k8s

Infraestrutura como código (Terraform) para provisionar o cluster Kubernetes EKS na AWS, além dos manifestos Kubernetes da aplicação.

## Responsabilidade

Este repositório provisiona o cluster EKS e aplica todos os manifestos Kubernetes da aplicação (`oficina-app`). O deploy da imagem em si é feito pelo pipeline do repositório `fiap-oficina`.

## Recursos provisionados

- **EKS Cluster** `oficina-cluster` — Kubernetes 1.32
- **Node Group** — 1 nó `t3.micro` (free tier)
- **IAM Roles** — para o cluster e para os nós

## Estrutura

```
oficina-infra-k8s/
├── main.tf           ← EKS cluster, node group, IAM roles
├── variables.tf      ← region, tipo e quantidade de nós
├── outputs.tf        ← cluster name, endpoint, comando kubeconfig
└── k8s/
    ├── namespace.yaml
    ├── configmap.yaml
    ├── deployment.yaml
    ├── service.yaml  ← LoadBalancer expondo porta 80
    └── hpa.yaml      ← autoescala entre 1 e 6 réplicas
```

> O secret com as credenciais do banco é criado automaticamente pelo workflow via `kubectl create secret --dry-run=client | kubectl apply`. Não há `secret.yaml` no repositório para evitar vazamento de credenciais.

## Custo

> **Atenção:** EKS não tem free tier.
> - Cluster: ~$0.10/h (~$7/mês)
> - 1 nó `t3.micro`: ~$0.01/h (~$8/mês)
>
> **Estratégia:** provisionar apenas para demonstração e destruir com `terraform destroy` logo após.

## Deploy (via GitHub Actions)

Actions → **Deploy Infraestrutura EKS** → Run workflow → selecione `apply` ou `destroy`

O workflow realiza, em ordem:
1. `terraform apply` — provisiona o cluster EKS
2. Configura o `kubectl` via `aws eks update-kubeconfig`
3. Escala o `coredns` para 1 réplica (libera slot de pod no t3.micro)
4. Aplica os manifestos: namespace, configmap, deployment, service, hpa
5. Cria o secret `oficina-secrets` com as credenciais do banco e JWT
6. Aguarda o rollout do deployment com timeout de 300s

## Observações sobre t3.micro

O t3.micro suporta no máximo 4 pods. Os pods do sistema (aws-node, kube-proxy, 2x coredns) ocupam todos os slots. Por isso o workflow escala o coredns para 1 réplica antes do deploy, liberando espaço para a aplicação.

O deployment usa estratégia `Recreate` (em vez de `RollingUpdate`) para evitar tentar criar um novo pod antes de terminar o antigo — o que causaria erro de capacidade insuficiente.

## Após o apply

O endpoint do LoadBalancer fica disponível via:

```bash
kubectl get svc -n oficina
```

> O DNS do LoadBalancer muda a cada `terraform destroy` + `terraform apply`. Para URL fixa em produção, use Route 53 apontando para o LoadBalancer.

## Secrets necessários no GitHub

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
| `DB_HOST` | Endpoint do RDS (disponível após oficina-infra-db) |
| `DB_PASSWORD` | Senha do banco de dados |
| `JWT_SECRET` | Mesmo secret usado na Lambda de autenticação |
