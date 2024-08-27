resource "tls_private_key" "default_ssh_key" {
  count = var.generate_default_ssh_key ? 1 : 0

  algorithm = "RSA"
}

resource "yandex_kubernetes_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_id = yandex_kubernetes_cluster.main.id
  name       = var.node_name_prefix != "" ? format("%s-%s", var.node_name_prefix, each.key) : each.key

  description = each.value["description"]
  labels      = lookup(each.value, "labels", var.labels)

  version = lookup(each.value, "version", var.master_version)

  instance_template {
    platform_id = each.value["platform_id"]
    metadata = merge(
      local.node_groups_ssh_keys_metadata,
      each.value["metadata"],
      var.enable_oslogin ? { "enable-oslogin" = "true" } : {}
    )

    resources {
      memory        = each.value["memory"]
      cores         = each.value["cores"]
      core_fraction = each.value["core_fraction"]
      gpus          = each.value["gpus"]
    }

    boot_disk {
      type = each.value["boot_disk_type"]
      size = each.value["boot_disk_size"]
    }

    scheduling_policy {
      preemptible = each.value["preemptible"]
    }

    dynamic "placement_policy" {
      for_each = compact([each.value["placement_group_id"]])

      content {
        placement_group_id = placement_policy.value
      }
    }

    network_interface {
      #
      # The logic is the following:
      #   if "node_groups" object contains "zones" key, take all "subnet_ids"
      #   variables in a list format based on "zones" from "node_groups_locations" variable.
      #
      #   otherwise, take the first one list of objects from "node_groups_locations"
      #
      subnet_ids = each.value["zones"] != null ? [
        for zone in each.value["zones"] : lookup(
          { for item in local.node_groups_locations : item.zone => item.subnet_id },
          zone,
          null
        )
        if lookup({ for item in local.node_groups_locations : item.zone => item.subnet_id }, zone, null) != null
        ] : [
        for location in [local.node_groups_locations[0]] : location.subnet_id
      ]

      ipv4               = true
      ipv6               = false
      nat                = each.value["nat"]
      security_group_ids = each.value.security_group_ids != null ? each.value.security_group_ids : var.node_groups_default_security_groups_ids
      # TODO: ipv4_dns_records
      # TODO: ipv6_dns_records
    }

    network_acceleration_type = each.value["network_acceleration_type"]

    dynamic "container_runtime" {
      for_each = compact([each.value["container_runtime_type"]])

      content {
        type = container_runtime.value
      }
    }
  }

  scale_policy {
    dynamic "fixed_scale" {
      for_each = each.value["fixed_scale"] != null && each.value["auto_scale"] == null ? [1] : []

      content {
        size = each.value["fixed_scale"]["size"]
      }
    }

    dynamic "auto_scale" {
      for_each = each.value["fixed_scale"] == null && each.value["auto_scale"] != null ? [1] : []

      content {
        min     = each.value["auto_scale"]["min"]
        max     = each.value["auto_scale"]["max"]
        initial = each.value["auto_scale"]["initial"]
      }
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = each.value["zones"] != null ? each.value["zones"] : [
        for location in [local.node_groups_locations[0]] : location.zone
      ]

      content {
        zone = location.value
      }
    }
  }

  maintenance_policy {
    auto_repair  = each.value["auto_repair"]
    auto_upgrade = each.value["auto_upgrade"]

    dynamic "maintenance_window" {
      for_each = lookup(each.value, "maintenance_windows", null) != null ? each.value["maintenance_windows"] : []

      content {
        day        = lookup(maintenance_window.value, "day", null)
        start_time = maintenance_window.value["start_time"]
        duration   = maintenance_window.value["duration"]
      }
    }
  }

  node_labels            = each.value["node_labels"]
  node_taints            = each.value["node_taints"]
  allowed_unsafe_sysctls = each.value["allowed_unsafe_sysctls"]

  dynamic "deploy_policy" {
    for_each = each.value["max_expansion"] != null || each.value["max_unavailable"] != null ? [1] : []

    content {
      max_expansion   = each.value["max_expansion"]
      max_unavailable = each.value["max_unavailable"]
    }
  }
}
