output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.oficina.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.oficina.endpoint
}

output "kubeconfig_command" {
  description = "Comando para configurar o kubectl"
  value       = "aws eks update-kubeconfig --region sa-east-1 --name oficina-cluster"
}
