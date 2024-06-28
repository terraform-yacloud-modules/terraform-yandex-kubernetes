module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account"

  name      = "iam"
  folder_id = "xxxx"
  folder_roles = [
    "admin",
  ]
  cloud_roles              = []
  enable_static_access_key = false
  enable_api_key           = false
  enable_account_key       = false

}

module "kube" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-kubernetes.git"

  network_id = "xxx"
  folder_id  = "xxx"

  name = "k8s-test"

  service_account_id      = module.iam_accounts.id
  node_service_account_id = module.iam_accounts.id

  master_region = "ru-central1"
  master_locations = [
    {
      zone      = "ru-central1-a"
      subnet_id = "xxx"
    },
    {
      zone      = "ru-central1-b"
      subnet_id = "xxx"
    },
    {
      zone      = "ru-central1-d"
      subnet_id = "xxx"
    }
  ]

}
