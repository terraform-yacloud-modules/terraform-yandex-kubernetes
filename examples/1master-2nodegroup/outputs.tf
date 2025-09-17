output "get_credentials_command" {
  description = "Command to get kubeconfig for the cluster"
  value       = module.kube.get_credentials_command
}
