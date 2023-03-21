output "external_v4_endpoint" {
  description = "An IPv4 external network address that is assigned to the master"
  value       = yandex_kubernetes_cluster.main.master[0].external_v4_endpoint
}

output "internal_v4_endpoint" {
  description = "An IPv4 internal network address that is assigned to the master"
  value       = yandex_kubernetes_cluster.main.master[0].internal_v4_endpoint
}

output "cluster_ca_certificate" {
  description = "PEM-encoded public certificate that is the root of trust for the K8S cluster"
  value       = yandex_kubernetes_cluster.main.master[0].cluster_ca_certificate
}

output "cluster_id" {
  description = "ID of a new K8S cluster"
  value       = yandex_kubernetes_cluster.main.id
}

output "node_groups" {
  description = "Attributes of yandex_node_group resources created in cluster"
  value       = yandex_kubernetes_node_group.node_groups
}

output "default_ssh_key_pub" {
  description = "Default node groups that is attached to all node groups"
  value       = var.generate_default_ssh_key ? tls_private_key.default_ssh_key[0].public_key_openssh : null
}

output "default_ssh_key_prv" {
  description = "Default node groups that is attached to all node groups"
  value       = var.generate_default_ssh_key ? tls_private_key.default_ssh_key[0].public_key_openssh : null
}
