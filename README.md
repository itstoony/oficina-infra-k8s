# oficina-infra-k8s

Infraestrutura como código (Terraform) para provisionar o cluster Kubernetes EKS na AWS, além dos manifestos Kubernetes da aplicação.

## Responsabilidade

Provisiona o cluster EKS e aplica todos os manifestos Kubernetes da aplicação (`oficina-app`). O deploy da imagem em si é feito pelo pipeline do repositório `fiap-oficina`.

## Tecnologias

| Tecnologia | Uso |
|---|---|
| Terraform >= 1.5 | Provisionamento do cluster EKS |
| AWS EKS 1.32 | Orquestração Kubernetes gerenciada |
| AWS EC2 t3.small | Nó do cluster (gravação do vídeo) / t3.micro (produção) |
| kubectl | Aplicação dos manifestos K8s |
| GitHub Actions | CI/CD (apply / destroy via workflow_dispatch) |
| New Relic K8s Integration | Monitoramento de CPU/memória dos pods |

## Arquitetura

```
GitHub Actions (workflow_dispatch: apply | destroy)
  │
  ├── terraform apply → EKS Cluster (oficina-cluster, sa-east-1)
  ├── kubectl scale coredns --replicas=1  ← libera slot de pod
  ├── kubectl apply → namespace, configmap, deployment, service, hpa
  ├── kubectl create secret → oficina-secrets (DB, JWT, New Relic)
  └── kubectl rollout status → aguarda app subir
            │
            ▼
      EKS Node (t3.small / t3.micro)
      ┌─────────────────────────────┐
      │  oficina-app (Spring Boot)  │
      │  HPA: 1-6 réplicas          │
      │  Strategy: Recreate         │
      └──────────┬──────────────────┘
                 │
      ┌──────────▼──────────────────┐
      │  LoadBalancer (ELB Classic) │
      │  porta 80                   │
      └─────────────────────────────┘
```

## Recursos provisionados

- **EKS Cluster** `oficina-cluster` — Kubernetes 1.32
- **Node Group** — 1 nó `t3.small` (vídeo) / `t3.micro` (produção)
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

## Custo e estratégia de deploy

> **Atenção:** EKS não tem free tier.
> - Cluster: ~$0.10/h (~$7/mês)
> - 1 nó `t3.micro`: ~$0.01/h / `t3.small`: ~$0.026/h
>
> **Estratégia:** a infraestrutura é provisionada sob demanda para demonstração e destruída logo após, evitando custos contínuos. O funcionamento completo está demonstrado no vídeo de entrega.

## Deploy (via GitHub Actions)

Actions → **Deploy Infraestrutura EKS** → Run workflow → selecione `apply` ou `destroy`

O workflow realiza, em ordem:
1. `terraform apply` — provisiona o cluster EKS
2. Configura o `kubectl` via `aws eks update-kubeconfig`
3. Escala o `coredns` para 1 réplica (libera slot de pod)
4. Aplica os manifestos: namespace, configmap, deployment, service, hpa
5. Cria o secret `oficina-secrets` com as credenciais do banco, JWT e New Relic
6. Aguarda o rollout do deployment com timeout de 300s

## Após o apply

```bash
aws eks update-kubeconfig --region sa-east-1 --name oficina-cluster
kubectl get svc -n oficina  # obtém o DNS do LoadBalancer
kubectl get pods -n oficina # verifica status dos pods
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
| `NEW_RELIC_LICENSE_KEY` | Chave de licença do New Relic |
