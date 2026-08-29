variable "region" {
  description = "Região AWS"
  type        = string
  default     = "sa-east-1"
}

variable "node_instance_type" {
  description = "Tipo de instância EC2 dos nós"
  type        = string
  default     = "t3.micro"
}

variable "node_desired" {
  description = "Número desejado de nós"
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Número máximo de nós"
  type        = number
  default     = 4
}

variable "node_min" {
  description = "Número mínimo de nós"
  type        = number
  default     = 1
}
