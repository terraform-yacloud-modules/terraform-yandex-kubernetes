module "iam_accounts" {
  for_each = {
  for k, v in var.iam : k => v if v["enabled"]
  }

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account"

  name = each.key

  folder_roles = each.value["folder_roles"]
  cloud_roles  = each.value["cloud_roles"]

  enable_static_access_key = each.value["enable_static_access_key"]
  enable_api_key           = each.value["enable_api_key"]
  enable_account_key       = each.value["enable_account_key"]
}

module "network" {
  source  = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git"

  blank_name = "test-network"
  labels     = {}

  azs = var.azs

  public_subnets  = var.subnets["public"]
  private_subnets = var.subnets["private"]
}

module "clusters" {
  for_each = var.clusters

  source = "../../"

  name        = each.key
  description = each.value["description"]
  labels      = {}

  network_id = module.network.vpc_id

  node_ipv4_cidr_mask_size = each.value["node_ipv4_cidr_mask_size"]
  kms_provider_key_id      = null
  master_version           = each.value["master_version"]
  master_public_ip         = each.value["master_public_ip"]

  master_locations = each.value["type"] == "zonal" ? [
    {
      zone      = module.network.private_subnets[0].zone
      subnet_id = module.network.private_subnets[0].id
    }
  ] : [
    {
      zone      = module.network.private_subnets[0].zone
      subnet_id = module.network.private_subnets[0].id
    },
    {
      zone      = module.network.private_subnets[1].zone
      subnet_id = module.network.private_subnets[1].id
    },
    {
      zone      = module.network.private_subnets[2].zone
      subnet_id = module.network.private_subnets[2].id
    }
  ]

  master_auto_upgrade        = each.value["master_auto_upgrade"]
  master_maintenance_windows = each.value["master_maintenance_windows"]
  master_logging             = each.value["master_logging"]

  service_account_id      = module.iam_accounts[format("%s-master", each.key)].id
  node_service_account_id = module.iam_accounts[format("%s-node", each.key)].id

  node_groups = each.value["node_groups"]

  depends_on = [
    module.iam_accounts
  ]
}
