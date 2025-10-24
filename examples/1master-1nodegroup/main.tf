data "yandex_client_config" "client" {}

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.0.0"

  folder_id = data.yandex_client_config.client.folder_id

  blank_name = "vpc-nat-gateway"
  labels = {
    repo = "terraform-yacloud-modules/terraform-yandex-vpc"
  }

  azs = ["ru-central1-a"]

  private_subnets = [["10.4.0.0/24"]]

  create_vpc         = true
  create_nat_gateway = true
}

module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account?ref=v1.0.0"

  name = "iam"
  folder_roles = [
    "container-registry.images.puller",
    "k8s.clusters.agent",
    "k8s.tunnelClusters.agent",
    "load-balancer.admin",
    "logging.writer",
    "vpc.privateAdmin",
    "vpc.publicAdmin",
    "vpc.user",
  ]
  cloud_roles              = []
  enable_static_access_key = false
  enable_api_key           = false
  enable_account_key       = false

}

module "kube" {
  source = "../../"

  network_id = module.network.vpc_id

  name        = "k8s-test"
  description = "Test Kubernetes cluster"
  labels = {
    environment = "test"
    project     = "terraform-yacloud-modules"
  }

  cluster_ipv4_range       = "10.112.0.0/16"
  service_ipv4_range       = "10.113.0.0/16"
  node_ipv4_cidr_mask_size = 24

  service_account_id      = module.iam_accounts.id
  node_service_account_id = module.iam_accounts.id

  release_channel = "STABLE"
  master_version  = "1.30"

  master_public_ip    = true
  master_auto_upgrade = false

  cni_type = "calico"

  workload_identity_federation = {
    enabled = false
  }

  master_locations = [
    {
      zone      = "ru-central1-a"
      subnet_id = module.network.private_subnets_ids[0]
    }
  ]

  master_maintenance_windows = [
    {
      start_time = "23:00"
      duration   = "3h"
    }
  ]

  master_logging = {
    enabled                    = false
    create_log_group           = true
    log_group_retention_period = "168h"
    audit_enabled              = true
    kube_apiserver_enabled     = true
    cluster_autoscaler_enabled = true
    events_enabled             = true
  }

  node_groups = {
    "default" = {
      description    = "Default node group"
      subnet_ids     = [module.network.private_subnets_ids[0]]
      nat            = true
      cores          = 2
      memory         = 8
      core_fraction  = 100
      boot_disk_type = "network-hdd"
      boot_disk_size = 100
      preemptible    = false
      fixed_scale = {
        size = 3
      }
      auto_repair  = true
      auto_upgrade = true
      node_labels = {
        node-type = "default"
      }
    }
  }

  generate_default_ssh_key = true
  nodes_default_ssh_user   = "ubuntu"

  depends_on = [module.iam_accounts]

}
