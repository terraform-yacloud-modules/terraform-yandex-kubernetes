data "yandex_client_config" "client" {}

module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account?ref=v1.0.0"

  name = "test-iam"
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

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.0.0"

  folder_id = data.yandex_client_config.client.folder_id

  blank_name = "redis-vpc-nat-gateway"
  labels = {
    repo = "terraform-yacloud-modules/terraform-yandex-vpc"
  }

  azs = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]

  private_subnets = [["10.10.0.0/24"], ["10.11.0.0/24"], ["10.12.0.0/24"]]

  create_vpc         = true
  create_nat_gateway = true
}

module "kube" {
  source = "../../"

  network_id = module.network.vpc_id

  name = "test-kubernetes" # Исправляем имя для выполнения destroy

  service_account_id      = "invalid-service-account-id" # Неправильный ID сервисного аккаунта
  node_service_account_id = "invalid-node-account-id"    # Неправильный ID сервисного аккаунта узлов

  master_locations = [
    {
      zone      = "invalid-zone"      # Неправильная зона
      subnet_id = "invalid-subnet-id" # Неправильный ID подсети
    }
  ]

  cluster_ipv4_range = "10.112.0.0/16" # Исправляем CIDR для получения следующих ошибок
  service_ipv4_range = "10.113.0.0/8"  # Слишком большой CIDR, может перекрывать другие сети

  node_ipv4_cidr_mask_size = 24 # Исправляем маску для получения следующих ошибок

  master_version = "invalid-version" # Неправильная версия K8S

  cni_type = "invalid-cni" # Неправильный тип CNI

  release_channel = "STABLE" # Исправляем канал релиза для получения следующих ошибок

  master_maintenance_windows = [
    {
      start_time = "23:00", # Исправляем время
      duration   = "3h"     # Исправляем длительность
    }
  ]

  node_groups = {
    "test-group" = {
      cores          = 2,                                      # Исправляем количество ядер для получения следующих ошибок
      memory         = 8,                                      # Исправляем память для получения следующих ошибок
      boot_disk_size = 100,                                    # Исправляем размер диска
      subnet_ids     = [module.network.private_subnets_ids[0]] # Добавляем subnet_ids
    }
  }

  depends_on = [
    module.iam_accounts
  ]
}
