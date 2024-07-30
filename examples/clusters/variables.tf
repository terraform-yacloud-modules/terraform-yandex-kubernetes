variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}

variable "subnets" {
  description = "A map of subnet configurations, where 'public' and 'private' keys contain lists of CIDR blocks for public and private subnets respectively."
  type        = map(list(list(string)))
  default = {
    public  = []
    private = [["10.4.0.0/24"], ["10.5.0.0/24"], ["10.6.0.0/24"]]
  }
}

variable "iam" {
  default = {
    cluster01-node = {
      enabled = true
      folder_roles = [
        "editor",
        "container-registry.images.puller",
        "k8s.tunnelClusters.agent"
      ]

      cloud_roles              = []
      enable_static_access_key = false
      enable_api_key           = false
      enable_account_key       = false
    }
    cluster01-master = {
      enabled                  = true
      folder_roles             = ["editor"]
      cloud_roles              = []
      enable_static_access_key = false
      enable_api_key           = false
      enable_account_key       = false
    }
  }
}

variable "clusters" {
  default = {
    "cluster01" = {
      description              = ""
      create_kms_key           = true
      node_ipv4_cidr_mask_size = 24

      type = "zonal"

      master_version      = "1.27"
      master_public_ip    = true
      master_auto_upgrade = false
      master_maintenance_windows = [
        {
          start_time = "23:00"
          duration   = "3h"
        }
      ]
      master_logging = {
        enabled                    = true
        create_log_group           = true
        log_group_retention_period = "72h"
        log_group_id               = ""
        kube_apiserver_enabled     = true
        cluster_autoscaler_enabled = true
        events_enabled             = true
      }

      generate_default_ssh_key = true
      nodes_default_ssh_user   = "ubuntu"

      node_groups = {
        "default" = {
          description = ""

          platform_id = "standard-v2"
          nat         = true

          memory         = 2
          cores          = 2
          core_fraction  = 100
          boot_disk_type = "network-hdd"
          boot_disk_size = 64

          preemptible = false

          container_runtime_type = "containerd"

          fixed_scale = {
            size = 1
          }

          auto_repair  = true
          auto_upgrade = true

          maintenance_windows = [
            {
              start_time = "23:00"
              duration   = "3h"
            }
          ]

          node_labels = {}
          node_taints = []
        }

        "middleware" = {
          description = ""

          platform_id = "standard-v2"
          nat         = true

          memory         = 2
          cores          = 2
          core_fraction  = 100
          boot_disk_type = "network-hdd"
          boot_disk_size = 64

          preemptible = false

          container_runtime_type = "containerd"

          auto_scale = {
            min     = 1
            max     = 3
            initial = 1
          }

          auto_repair  = true
          auto_upgrade = true

          maintenance_windows = [
            {
              start_time = "23:00"
              duration   = "3h"
            }
          ]

          node_labels = {
            dedicated = "middleware"
          }
          node_taints = [
            "dedicated=middleware:NoSchedule"
          ]
        }
      }
    }
  }
}
