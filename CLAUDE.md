# CLAUDE.md — oficina-infra-k8s
## FIAP Pós-Tech Software Architecture — Fase 3

---

## CONTEXTO

Este repositório provisiona o **cluster EKS (Kubernetes gerenciado)** e contém os manifestos Kubernetes da aplicação.

**Account ID:** 302789973247
**Região:** sa-east-1
**Bucket state Terraform:** `oficina-terraform-state-302789973247`

**Os 4 repositórios da Fase 3:**
- `oficina-lambda` → https://github.com/itstoony/oficina-lambda.git — **CONCLUÍDO**
- `oficina-infra-db` → https://github.com/itstoony/oficina-infra-db.git — **CONCLUÍDO**
- `oficina-infra-k8s` ← este repositório
- `oficina-app` → https://github.com/itstoony/fiap-oficina.git

---

## PADRÕES DO PROJETO

- Commits em **português do Brasil** seguindo conventional commits
- Branches: `develop` → `homolog` → `main`
- `main` protegida: PR obrigatório com 1 aprovação + CI verde
- Sem co-authoria de ferramentas nos commits

---

## RESPONSABILIDADE

- Provisionar cluster EKS via Terraform
- Provisionar Node Group com autoescala
- Conter os manifestos Kubernetes da aplicação (namespace, secret, configmap, deployment, service, hpa)

---

## ESTRUTURA

```
oficina-infra-k8s/
├── main.tf                     ← EKS cluster, node group, IAM roles
├── variables.tf                ← region, tipo e quantidade de nós
├── outputs.tf                  ← cluster name, endpoint, kubeconfig command
├── k8s/
│   ├── namespace.yaml
│   ├── secret.yaml             ← substituir PLACEHOLDERs antes de aplicar
│   ├── configmap.yaml
│   ├── deployment.yaml         ← imagem ECR, probes, resources
│   ├── service.yaml            ← LoadBalancer porta 80 → 8080
│   └── hpa.yaml                ← min 2, max 6 réplicas, CPU 70% / mem 80%
├── .github/
│   └── workflows/
│       ├── ci.yml              ← validate + plan em push/PR
│       └── deploy.yml          ← apply ou destroy manual via workflow_dispatch
└── README.md
```

---

## DECISÕES TÉCNICAS

- **Deploy manual:** EKS tem custo (~$67/mês) — deploy só quando for gravar o vídeo, destroy logo após
- **workflow_dispatch com opção apply/destroy:** permite subir e derrubar o cluster direto do GitHub Actions
- **Node type `t3.medium`:** mínimo para rodar o Spring Boot com folga
- **Service LoadBalancer:** expõe a aplicação via ELB da AWS automaticamente
- **HPA:** autoescala entre 2 e 6 réplicas baseado em CPU (70%) e memória (80%)
- **Probes:** liveness e readiness apontando para `/actuator/health`
- **Imagem ECR:** `302789973247.dkr.ecr.sa-east-1.amazonaws.com/oficina-app:latest`

---

## CI/CD

| Trigger | Job | O que faz |
|---|---|---|
| push/PR em qualquer branch | CI | `terraform validate` + `terraform plan` |
| workflow_dispatch (apply) | Deploy | `terraform apply` — sobe o cluster |
| workflow_dispatch (destroy) | Deploy | `terraform destroy` — derruba o cluster |

---

## STATUS

- [x] `main.tf` — implementado
- [x] `variables.tf` — implementado
- [x] `outputs.tf` — implementado
- [x] `k8s/` — manifestos implementados
- [x] `ci.yml` — implementado
- [x] `deploy.yml` — implementado (manual)
- [x] `README.md` — implementado
- [ ] Secrets no GitHub configurados
- [ ] ECR repository criado
- [ ] Deploy do EKS — aguarda conclusão do oficina-app

---

## ANTES DO DEPLOY

1. Criar repositório ECR: `aws ecr create-repository --repository-name oficina-app --region sa-east-1`
2. Substituir PLACEHOLDERs no `k8s/secret.yaml`
3. Configurar secrets no GitHub (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
4. Actions → Deploy Infraestrutura EKS → Run workflow → `apply`
5. Após o apply: `aws eks update-kubeconfig --region sa-east-1 --name oficina-cluster`
6. `kubectl apply -f k8s/`

## APÓS O VÍDEO

Actions → Deploy Infraestrutura EKS → Run workflow → `destroy`

---

## PRÓXIMO PASSO

Trabalhar no `oficina-app` (fiap-oficina) — adaptar autenticação, adicionar Datadog, CI/CD para ECR + EKS.
