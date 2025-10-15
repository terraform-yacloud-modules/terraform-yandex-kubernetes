data "yandex_client_config" "client" {}

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.0.0"

  folder_id = data.yandex_client_config.client.folder_id

  blank_name = "vpc-nat-gateway"
  labels = {
    repo = "terraform-yacloud-modules/terraform-yandex-vpc"
  }

  azs = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]

  private_subnets = [["10.4.0.0/24"], ["10.5.0.0/24"], ["10.6.0.0/24"]]

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

  name = "k8s-test4"

  service_account_id      = module.iam_accounts.id
  node_service_account_id = module.iam_accounts.id

  master_region = "ru-central1"

  master_locations = [
    {
      zone      = "ru-central1-a"
      subnet_id = module.network.private_subnets_ids[0]
    },
    {
      zone      = "ru-central1-b"
      subnet_id = module.network.private_subnets_ids[1]
    },
    {
      zone      = "ru-central1-d"
      subnet_id = module.network.private_subnets_ids[2]
    }
  ]

  node_groups = {
    "fixed-scale" = {
      nat    = true
      cores  = 2
      memory = 4
      fixed_scale = {
        size = 1
      }
      zones      = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
      subnet_ids = [module.network.private_subnets_ids[0], module.network.private_subnets_ids[1], module.network.private_subnets_ids[2]] # Укажите соответствующие подсети
    }

    "auto-scale-a" = {
      nat    = true
      cores  = 2
      memory = 8
      auto_scale = {
        min     = 1
        max     = 5
        initial = 1
      }
      zones      = ["ru-central1-a"]
      subnet_ids = [module.network.private_subnets_ids[0]]
    }

    "auto-scale-b" = {
      nat    = true
      cores  = 2
      memory = 8
      auto_scale = {
        min     = 1
        max     = 5
        initial = 1
      }
      zones      = ["ru-central1-b"]
      subnet_ids = [module.network.private_subnets_ids[1]]
    }
  }

  depends_on = [module.iam_accounts]

}
