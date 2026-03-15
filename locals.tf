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

  node_groups_locations = var.node_groups_locations != null ? var.node_groups_locations : var.master_locations

  # Only one of log_group_id or folder_id may be set for master_logging
  master_logging_log_group_id = var.master_logging["folder_id"] != "" ? null : (
    var.master_logging["log_group_id"] != "" ? var.master_logging["log_group_id"] : (var.master_logging["create_log_group"] ? yandex_logging_group.main[0].id : null)
  )
  master_logging_folder_id = var.master_logging["folder_id"] != "" ? var.master_logging["folder_id"] : null
}
