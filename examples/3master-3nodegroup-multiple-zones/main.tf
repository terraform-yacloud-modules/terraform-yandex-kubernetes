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

  network_id = "xxxx"

  name = "k8s-test"

  service_account_id      = module.iam_accounts.id
  node_service_account_id = module.iam_accounts.id

  master_region = "ru-central1"

  master_locations = [
    {
      zone      = "ru-central1-a"
      subnet_id = "xxxx"
    },
    {
      zone      = "ru-central1-b"
      subnet_id = "xxxx"
    },
    {
      zone      = "ru-central1-d"
      subnet_id = "xxxx"
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
      zones      = ["ru-central1-a", "ru-central1-d"]
      subnet_ids = ["xxxx", "xxxx"] # Укажите соответствующие подсети
    }

    "auto-scale-1" = {
      nat    = true
      cores  = 2
      memory = 8
      auto_scale = {
        min     = 1
        max     = 5
        initial = 1
      }
    }

    "auto-scale-2" = {
      nat    = true
      cores  = 2
      memory = 8
      auto_scale = {
        min     = 1
        max     = 5
        initial = 1
      }
      zones = ["ru-central1-d"]
    }
  }

  depends_on = [module.iam_accounts]

}
