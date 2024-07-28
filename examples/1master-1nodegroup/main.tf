module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account"

  name      = "iam"
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
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-kubernetes.git"

  network_id = "xxxx"

  name = "k8s-test"

  service_account_id      = module.iam_accounts.id
  node_service_account_id = module.iam_accounts.id

  master_locations = [
    {
      zone      = "ru-central1-a"
      subnet_id = "xxxx"
    }
  ]

  node_groups = {
    "default" = {
      nat    = true
      cores  = 2
      memory = 8
      fixed_scale = {
        size = 3
      }
    }
  }

  depends_on = [ module.iam_accounts ]

}
