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
  value       = var.generate_default_ssh_key ? tls_private_key.default_ssh_key[0].private_key_openssh : null
}

output "get_credentials_command" {
  description = "Command to get kubeconfig for the cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.main.id} --external"
}

output "log_group_id" {
  description = "ID of the Yandex Cloud Logging group"
  value       = var.master_logging["create_log_group"] ? yandex_logging_group.logging_group[0].id : null
}

output "log_group_name" {
  description = "Name of the Yandex Cloud Logging group"
  value       = var.master_logging["create_log_group"] ? yandex_logging_group.logging_group[0].name : null
}
