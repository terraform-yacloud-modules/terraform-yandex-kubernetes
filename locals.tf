locals {
  master_regions = length(var.master_locations) > 1 ? [
    {
      region    = var.master_region
      locations = var.master_locations
    }
  ] : []

  master_locations = length(var.master_locations) > 1 ? [] : var.master_locations

  generated_ssh_key = var.generate_default_ssh_key ? [
    "${var.nodes_default_ssh_user}:${tls_private_key.default_ssh_key[0].public_key_openssh}"
  ] : []

  node_groups_ssh_keys_metadata = length(var.node_groups_ssh_keys) > 0 ? {
    ssh-keys = join("\n", concat(flatten([
      for username, ssh_keys in var.node_groups_ssh_keys : [
        for ssh_key in ssh_keys
        : "${username}:${ssh_key}"
      ]
      ], [local.generated_ssh_key])
    ))
  } : {}

  node_groups_default_locations = coalesce(var.node_groups_default_locations, var.master_locations)
}
