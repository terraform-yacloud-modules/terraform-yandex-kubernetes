#
# yandex cloud coordinates
#
variable "folder_id" {
  description = "Folder ID"
  type        = string
  default     = null
}

#
# naming
#
variable "name" {
  description = "K8S cluster name"
  type        = string
}

variable "description" {
  description = "K8S cluster description"
  type        = string
  default     = ""
}

variable "labels" {
  description = "A set of labels to assign to the K8S cluster"
  type        = map(string)
  default     = {}
}

#
# K8S сluster network
#
variable "network_id" {
  description = "The ID of the cluster network"
  type        = string
  default     = null
}

variable "cluster_ipv4_range" {
  description = <<-EOF
  CIDR block. IP range for allocating pod addresses. It should not overlap with
  any subnet in the network the K8S cluster located in. Static routes will
  be set up for this CIDR blocks in node subnets
  EOF
  type        = string
  default     = null
}

variable "cluster_ipv6_range" {
  description = "Identical to cluster_ipv4_range but for IPv6 protocol"
  type        = string
  default     = null
}

variable "node_ipv4_cidr_mask_size" {
  description = <<-EOF
  Size of the masks that are assigned to each node in the cluster. Effectively
  limits maximum number of pods for each node
  EOF
  type        = number
  default     = null
}

variable "service_ipv4_range" {
  description = <<-EOF
  CIDR block. IP range K8S service K8S cluster IP addresses
  will be allocated from. It should not overlap with any subnet in the network
  the K8S cluster located in
  EOF
  type        = string
  default     = null
}

variable "service_ipv6_range" {
  description = "Identical to service_ipv4_range but for IPv6 protocol"
  type        = string
  default     = null
}

variable "cni_type" {
  description = "Type of K8S CNI which will be used for the cluster"
  type        = string
  default     = "calico"
}

#
# Cluster IAM
#
variable "service_account_id" {
  description = <<-EOF
  ID of existing service account to be used for provisioning Compute Cloud
  and VPC resources for K8S cluster. Selected service account should have
  edit role on the folder where the K8S cluster will be located and on the
  folder where selected network resides
  EOF
  type        = string
  default     = null
}

variable "node_service_account_id" {
  description = <<-EOF
  ID of service account to be used by the worker nodes of the K8S
  cluster to access Container Registry or to push node logs and metrics.

  If omitted or equal to `service_account_id`, service account will be used
  as node service account.
  EOF
  type        = string
  default     = null
}

#
# Cluster options
#
variable "release_channel" {
  description = "K8S cluster release channel"
  type        = string
  default     = "STABLE"
}

variable "kms_provider_key_id" {
  description = "K8S cluster KMS key ID"
  type        = string
  default     = null
}

#
# Master options
#
variable "master_version" {
  description = "Version of K8S that will be used for master"
  type        = string
  default     = "1.26"
}

variable "master_public_ip" {
  description = "Boolean flag. When true, K8S master will have visible ipv4 address"
  type        = bool
  default     = true
}

variable "master_security_group_ids" {
  description = "List of security group IDs to which the K8S cluster belongs"
  type        = set(string)
  default     = null
}

variable "master_region" {
  description = <<-EOF
  Name of region where cluster will be created. Required for regional cluster,
  not used for zonal cluster
  EOF
  type        = string
  default     = null
}

variable "master_locations" {
  description = <<-EOF
  List of locations where cluster will be created. If list contains only one
  location, will be created zonal cluster, if more than one -- regional
  EOF
  type = list(object({
    subnet_id = string
    zone      = string
  }))
}

variable "master_auto_upgrade" {
  description = "Boolean flag that specifies if master can be upgraded automatically"
  type        = bool
  default     = false
}

variable "master_maintenance_windows" {
  description = <<EOF
  List of structures that specifies maintenance windows,
  when auto update for master is allowed

  E.g:
  ```
  master_maintenance_windows = [
    {
      start_time = "10:00"
      duration   = "5h"
    }
  ]
  ```
  EOF
  type        = list(map(string))
  default = [
    {
      start_time = "23:00"
      duration   = "3h"
    }
  ]
}


variable "master_logging" {
  description = "Master logging"
  type = object({
    enabled                    = bool
    create_log_group           = optional(bool, true)
    log_group_retention_period = optional(string, "168h")
    log_group_id               = optional(string, "")
    kube_apiserver_enabled     = optional(bool, true)
    cluster_autoscaler_enabled = optional(bool, true)
    events_enabled             = optional(bool, true)
  })
  default = {
    enabled = true
  }
}

#
# Cluster node groups
#
variable "node_name_prefix" {
  description = "The prefix for node group name"
  type        = string
  default     = ""
}
variable "node_groups" {
  description = "K8S node groups"
  type = map(object({
    description               = optional(string, null)
    labels                    = optional(map(string), null)
    version                   = optional(string, null)
    metadata                  = optional(map(string), {})
    platform_id               = optional(string, null)
    memory                    = optional(string, 2)
    cores                     = optional(string, 2)
    core_fraction             = optional(string, 100)
    gpus                      = optional(string, null)
    boot_disk_type            = optional(string, "network-hdd")
    boot_disk_size            = optional(string, 100)
    preemptible               = optional(bool, false)
    placement_group_id        = optional(string, null)
    nat                       = optional(bool, false)
    security_group_ids        = optional(list(string))
    network_acceleration_type = optional(string, null)
    container_runtime_type    = optional(string, "containerd")
    fixed_scale               = optional(map(string), null)
    auto_scale                = optional(map(string), null)
    auto_repair               = optional(bool, true)
    auto_upgrade              = optional(bool, true)
    maintenance_windows       = optional(list(any))
    node_labels               = optional(map(string), null)
    node_taints               = optional(list(string), null)
    allowed_unsafe_sysctls    = optional(list(string), [])
    max_expansion             = optional(string, null)
    max_unavailable           = optional(string, null)
  }))
  default = {}
}

variable "generate_default_ssh_key" {
  description = "If true, SSH key for node groups will be generated"
  type        = bool
  default     = true
}

variable "nodes_default_ssh_user" {
  description = "Default SSH user for node groups. Used only if generate_default_ssh_key == true"
  type        = string
  default     = "ubuntu"
}

variable "node_groups_ssh_keys" {
  description = <<-EOF
  Map containing SSH keys to install on all K8S node servers by default
  EOF
  type        = map(list(string))
  default     = {}
}

variable "node_groups_locations" {
  description = "Locations of K8S node groups. If omitted, master_locations will be used"
  type = list(object({
    subnet_id = string
    zone      = string
  }))
  default = null
}

variable "node_groups_default_security_groups_ids" {
  description = "A list of default IDs for node groups. Will be used if node_groups[<group>].security_group_ids is empty"
  type        = list(string)
  default     = []
}
