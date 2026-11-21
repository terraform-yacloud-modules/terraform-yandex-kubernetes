# Kubernetes в Yandex Cloud: Terraform-модуль

Terraform-модуль создаёт управляемый кластер Kubernetes в Yandex Cloud:
master, группы узлов и сопутствующие ресурсы.

## Что умеет модуль

- Зональный (`master_locations` из одного элемента) и региональный
  (несколько `master_locations` и `master_region`) master.
- Выбор версии Kubernetes, канала релизов, публичного IP и групп безопасности
  для master.
- Политики обслуживания и окна обслуживания для master и групп узлов.
- Логирование master в Yandex Cloud Logging: существующая группа логов,
  группа по умолчанию каталога или автоматически создаваемая группа.
- CNI Calico или Cilium.
- Шифрование секретов в KMS.
- Workload Identity Federation на уровне кластера и с переопределением для
  каждой группы узлов.
- Группы узлов с фиксированным или автоматическим масштабированием,
  предварительно создаваемыми (`preemptible`) и обычными ВМ, GPU, дисками
  нужного типа и размера, метками, taint'ами, DNS-записями, политикой
  размещения и шаблоном имени ВМ.
- **Несколько диапазонов pod-адресов** — параметры `cluster_ipv4_ranges` и
  `cluster_ipv6_ranges`.
- **Управление доступом к API кластера по IAM** — параметр
  `cluster_iam_members`.

## Несколько диапазонов pod-адресов

Параметр `cluster_ipv4_ranges` позволяет задать до восьми CIDR-блоков для
pod-адресов. Это нужно, когда одного диапазона перестаёт хватать: диапазоны
можно расширять, не пересоздавая кластер.

```hcl
module "kube" {
  source = "terraform-yacloud-modules/kubernetes/yandex"

  # ...

  release_channel     = "RAPID"
  master_version      = "1.35"
  cluster_ipv4_ranges = ["10.112.0.0/16", "10.114.0.0/16"]

  # Одновременно с cluster_ipv4_ranges нельзя использовать cluster_ipv4_range:
  # cluster_ipv4_range  = "10.112.0.0/16"
  # cluster_ipv4_ranges = null
}
```

Важно:

- `cluster_ipv4_ranges` и `cluster_ipv4_range` взаимоисключающие, то же
  правило действует для `cluster_ipv6_ranges` и `cluster_ipv6_range`;
- обновление списка идёт только добавлением: существующие диапазоны нужно
  сохранять на своих местах и добавлять новые в конец;
- диапазоны не должны пересекаться с подсетями сети кластера и с
  `service_ipv4_range`;
- в списке может быть от 1 до 8 CIDR-блоков;
- несколько диапазонов Yandex Cloud принимает пока только на канале
  `RAPID` (проверено на Kubernetes 1.35). На каналах `STABLE` и `REGULAR`
  API отвечает ошибкой `multiple cluster CIDR blocks is not supported`.
  Одиночный диапазон в списке работает на любом канале;
- старые параметры `cluster_ipv4_range` и `cluster_ipv6_range` не удалены:
  модуль переводит их в список из одного элемента, поэтому обновление
  существующих кластеров не требует изменений в конфигурации.

Диапазоны поддерживаются провайдером `yandex-cloud/yandex` начиная с версии
`0.234.0` — модуль требует её в `versions.tf`.

## Доступ к API кластера по IAM

Параметр `cluster_iam_members` выдаёт роли на кластер указанным субъектам.
Ключ — роль, значение — набор участников в формате IAM Yandex Cloud:
`userAccount:<id>`, `serviceAccount:<id>`, `group:<id>`,
`federatedUser:<id>`.

```hcl
resource "yandex_iam_service_account" "viewer" {
  folder_id = var.folder_id
  name      = "k8s-viewer"
}

module "kube" {
  source = "terraform-yacloud-modules/kubernetes/yandex"

  # ...

  cluster_iam_members = {
    "k8s.cluster-api.viewer" = [
      "serviceAccount:${yandex_iam_service_account.viewer.id}",
    ]
  }
}
```

Для каждой роли создаётся отдельный ресурс
`yandex_kubernetes_cluster_iam_binding`, поэтому модуль управляет полным
набором участников для перечисленных ролей: участники, выданные этой роли
вне модуля, будут удалены при следующем `apply`. Не перечисленные в
`cluster_iam_members` роли модуль не трогает. Проверить результат можно
командой:

```bash
yc managed-kubernetes cluster list-access-bindings --name <имя-кластера>
```

## Примеры

Каталог [`examples`](https://github.com/terraform-yacloud-modules/terraform-yandex-kubernetes/tree/main/examples)
содержит готовые конфигурации. Они же используются для проверки изменений
модуля.

| Пример | Что показывает |
| --- | --- |
| [`simple`](examples/simple) | Минимальный кластер без групп узлов |
| [`1master-1nodegroup`](examples/1master-1nodegroup) | Один master и одна группа узлов |
| [`1master-1nodegroup-enable-logging`](examples/1master-1nodegroup-enable-logging) | Логирование master в группу логов каталога |
| [`1master-2nodegroup`](examples/1master-2nodegroup) | Две группы узлов: фиксированная и автомасштабируемая, Workload Identity Federation |
| [`complete`](examples/complete) | Все возможности модуля: несколько диапазонов pod-адресов, IAM-доступ, автомасштабирование, зоны `ru-central1-a` и `ru-central1-d` |

Запуск любого примера:

```bash
cd examples/complete

export YC_TOKEN="$(yc iam create-token)"
export YC_CLOUD_ID="$(yc config get cloud-id)"

terraform init
terraform apply -var folder_id=<id-каталога>
terraform destroy -var folder_id=<id-каталога>
```

## Требования

Модуль требует Terraform `>= 1.3`, провайдер `yandex-cloud/yandex` версии
`>= 0.234.0` и провайдер `hashicorp/tls` версии `>= 3.1.0`. Полные таблицы
входных параметров и выходных значений приведены ниже.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.1.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.234.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 3.1.0 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | >= 0.234.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [tls_private_key.default_ssh_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [yandex_kubernetes_cluster.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) | resource |
| [yandex_kubernetes_cluster_iam_binding.bindings](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster_iam_binding) | resource |
| [yandex_kubernetes_node_group.node_groups](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group) | resource |
| [yandex_logging_group.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/logging_group) | resource |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_iam_members"></a> [cluster\_iam\_members](#input\_cluster\_iam\_members) | Map of cluster IAM roles to the lists of members that will be granted on the<br/>K8S cluster. Members use Yandex Cloud IAM format: `userAccount:<id>`,<br/>`serviceAccount:<id>`, `group:<id>` or `federatedUser:<id>`.<br/><br/>The module owns the full member list for every role listed here: members<br/>granted to the same role outside the module are removed on apply.<br/>Roles that are not listed are left untouched.<br/><br/>E.g:<pre>cluster_iam_members = {<br/>  "k8s.cluster-api.viewer" = ["serviceAccount:<service-account-id>"]<br/>}</pre> | `map(set(string))` | `{}` | no |
| <a name="input_cluster_ipv4_range"></a> [cluster\_ipv4\_range](#input\_cluster\_ipv4\_range) | CIDR block. IP range for allocating pod addresses. It should not overlap with<br/>any subnet in the network the K8S cluster located in. Static routes will<br/>be set up for this CIDR blocks in node subnets | `string` | `null` | no |
| <a name="input_cluster_ipv4_ranges"></a> [cluster\_ipv4\_ranges](#input\_cluster\_ipv4\_ranges) | List of CIDR blocks for allocating pod IPv4 addresses. Cannot be set together<br/>with `cluster_ipv4_range`. Updates are append-only: keep the existing CIDRs<br/>and append new ones at the end. At most 8 CIDRs are allowed. | `list(string)` | `null` | no |
| <a name="input_cluster_ipv6_range"></a> [cluster\_ipv6\_range](#input\_cluster\_ipv6\_range) | Identical to cluster\_ipv4\_range but for IPv6 protocol | `string` | `null` | no |
| <a name="input_cluster_ipv6_ranges"></a> [cluster\_ipv6\_ranges](#input\_cluster\_ipv6\_ranges) | Identical to `cluster_ipv4_ranges` but for IPv6 protocol. Cannot be set<br/>together with `cluster_ipv6_range`. | `list(string)` | `null` | no |
| <a name="input_cni_type"></a> [cni\_type](#input\_cni\_type) | Type of K8S CNI which will be used for the cluster | `string` | `"calico"` | no |
| <a name="input_description"></a> [description](#input\_description) | K8S cluster description | `string` | `""` | no |
| <a name="input_enable_oslogin"></a> [enable\_oslogin](#input\_enable\_oslogin) | Enable OS Login for node groups | `bool` | `false` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | Folder ID | `string` | `null` | no |
| <a name="input_generate_default_ssh_key"></a> [generate\_default\_ssh\_key](#input\_generate\_default\_ssh\_key) | If true, SSH key for node groups will be generated | `bool` | `true` | no |
| <a name="input_kms_provider_key_id"></a> [kms\_provider\_key\_id](#input\_kms\_provider\_key\_id) | K8S cluster KMS key ID | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A set of labels to assign to the K8S cluster | `map(string)` | `{}` | no |
| <a name="input_master_auto_upgrade"></a> [master\_auto\_upgrade](#input\_master\_auto\_upgrade) | Boolean flag that specifies if master can be upgraded automatically | `bool` | `false` | no |
| <a name="input_master_locations"></a> [master\_locations](#input\_master\_locations) | List of locations where cluster will be created. If list contains only one<br/>location, will be created zonal cluster, if more than one -- regional | <pre>list(object({<br/>    subnet_id = string<br/>    zone      = string<br/>  }))</pre> | n/a | yes |
| <a name="input_master_logging"></a> [master\_logging](#input\_master\_logging) | Master logging. Only one of log\_group\_id or folder\_id may be set.<br/>If log\_group\_id is set, logs go to that group. If folder\_id is set, logs go to folder's default log group.<br/>If neither is set (and enabled=true), logs go to the cluster folder's default log group. | <pre>object({<br/>    enabled                    = bool<br/>    create_log_group           = optional(bool, true)<br/>    log_group_retention_period = optional(string, "168h")<br/>    log_group_id               = optional(string, "")<br/>    folder_id                  = optional(string, "")<br/>    audit_enabled              = optional(bool, true)<br/>    kube_apiserver_enabled     = optional(bool, true)<br/>    cluster_autoscaler_enabled = optional(bool, true)<br/>    events_enabled             = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_master_maintenance_windows"></a> [master\_maintenance\_windows](#input\_master\_maintenance\_windows) | List of structures that specifies maintenance windows,<br/>  when auto update for master is allowed<br/><br/>  E.g:<pre>master_maintenance_windows = [<br/>    {<br/>      start_time = "10:00"<br/>      duration   = "5h"<br/>    }<br/>  ]</pre> | `list(map(string))` | <pre>[<br/>  {<br/>    "duration": "3h",<br/>    "start_time": "23:00"<br/>  }<br/>]</pre> | no |
| <a name="input_master_public_ip"></a> [master\_public\_ip](#input\_master\_public\_ip) | Boolean flag. When true, K8S master will have visible ipv4 address | `bool` | `true` | no |
| <a name="input_master_region"></a> [master\_region](#input\_master\_region) | Name of region where cluster will be created. Required for regional cluster,<br/>not used for zonal cluster | `string` | `null` | no |
| <a name="input_master_security_group_ids"></a> [master\_security\_group\_ids](#input\_master\_security\_group\_ids) | List of security group IDs to which the K8S cluster belongs | `set(string)` | `null` | no |
| <a name="input_master_version"></a> [master\_version](#input\_master\_version) | Version of K8S that will be used for master | `string` | `"1.33"` | no |
| <a name="input_name"></a> [name](#input\_name) | K8S cluster name | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The ID of the cluster network | `string` | `null` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | K8S node groups | <pre>map(object({<br/>    description                  = optional(string, null)<br/>    labels                       = optional(map(string), null)<br/>    instance_labels              = optional(map(string), null)<br/>    version                      = optional(string, null)<br/>    metadata                     = optional(map(string), {})<br/>    platform_id                  = optional(string, null)<br/>    memory                       = optional(number, 2)<br/>    cores                        = optional(number, 2)<br/>    core_fraction                = optional(number, 100)<br/>    gpus                         = optional(number, null)<br/>    boot_disk_type               = optional(string, "network-hdd")<br/>    boot_disk_size               = optional(number, 100) # min 64 GB per provider<br/>    preemptible                  = optional(bool, false)<br/>    placement_group_id           = optional(string, null)<br/>    nat                          = optional(bool, false)<br/>    security_group_ids           = optional(list(string))<br/>    network_acceleration_type    = optional(string, "standard")<br/>    container_runtime_type       = optional(string, "containerd")<br/>    fixed_scale                  = optional(map(string), null)<br/>    auto_scale                   = optional(map(string), null)<br/>    auto_repair                  = optional(bool, true)<br/>    auto_upgrade                 = optional(bool, true)<br/>    maintenance_windows          = optional(list(any))<br/>    node_labels                  = optional(map(string), null)<br/>    node_taints                  = optional(list(string), null)<br/>    allowed_unsafe_sysctls       = optional(list(string), [])<br/>    max_expansion                = optional(number, null)<br/>    max_unavailable              = optional(number, null)<br/>    zones                        = optional(list(string), null)<br/>    subnet_ids                   = optional(list(string), null)<br/>    gpu_settings                 = optional(map(string), null)<br/>    container_network_mtu        = optional(number, null)<br/>    instance_name_template       = optional(string, null)<br/>    placement_policy             = optional(map(string), null)<br/>    ipv4_dns_records             = optional(list(map(string)), [])<br/>    ipv6_dns_records             = optional(list(map(string)), [])<br/>    workload_identity_federation = optional(bool, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_node_groups_default_security_groups_ids"></a> [node\_groups\_default\_security\_groups\_ids](#input\_node\_groups\_default\_security\_groups\_ids) | A list of default IDs for node groups. Will be used if node\_groups[<group>].security\_group\_ids is empty | `list(string)` | `[]` | no |
| <a name="input_node_groups_locations"></a> [node\_groups\_locations](#input\_node\_groups\_locations) | Locations of K8S node groups. If omitted, master\_locations will be used | <pre>list(object({<br/>    subnet_id = string<br/>    zone      = string<br/>  }))</pre> | `null` | no |
| <a name="input_node_groups_ssh_keys"></a> [node\_groups\_ssh\_keys](#input\_node\_groups\_ssh\_keys) | Map containing SSH keys to install on all K8S node servers by default | `map(list(string))` | `{}` | no |
| <a name="input_node_ipv4_cidr_mask_size"></a> [node\_ipv4\_cidr\_mask\_size](#input\_node\_ipv4\_cidr\_mask\_size) | Size of the masks that are assigned to each node in the cluster. Effectively<br/>limits maximum number of pods for each node | `number` | `null` | no |
| <a name="input_node_name_prefix"></a> [node\_name\_prefix](#input\_node\_name\_prefix) | The prefix for node group name | `string` | `""` | no |
| <a name="input_node_service_account_id"></a> [node\_service\_account\_id](#input\_node\_service\_account\_id) | ID of service account to be used by the worker nodes of the K8S<br/>cluster to access Container Registry or to push node logs and metrics.<br/><br/>If omitted or equal to `service_account_id`, service account will be used<br/>as node service account. | `string` | `null` | no |
| <a name="input_nodes_default_ssh_user"></a> [nodes\_default\_ssh\_user](#input\_nodes\_default\_ssh\_user) | Default SSH user for node groups. Used only if generate\_default\_ssh\_key == true | `string` | `"ubuntu"` | no |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | K8S cluster release channel | `string` | `"STABLE"` | no |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | ID of existing service account to be used for provisioning Compute Cloud<br/>and VPC resources for K8S cluster. Selected service account should have<br/>edit role on the folder where the K8S cluster will be located and on the<br/>folder where selected network resides | `string` | `null` | no |
| <a name="input_service_ipv4_range"></a> [service\_ipv4\_range](#input\_service\_ipv4\_range) | CIDR block. IP range K8S service K8S cluster IP addresses<br/>will be allocated from. It should not overlap with any subnet in the network<br/>the K8S cluster located in | `string` | `null` | no |
| <a name="input_service_ipv6_range"></a> [service\_ipv6\_range](#input\_service\_ipv6\_range) | Identical to service\_ipv4\_range but for IPv6 protocol | `string` | `null` | no |
| <a name="input_workload_identity_federation"></a> [workload\_identity\_federation](#input\_workload\_identity\_federation) | Workload Identity Federation configuration. Node groups inherit `enabled` unless they set `workload_identity_federation` in `node_groups` | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | PEM-encoded public certificate that is the root of trust for the K8S cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of a new K8S cluster |
| <a name="output_default_ssh_key_prv"></a> [default\_ssh\_key\_prv](#output\_default\_ssh\_key\_prv) | Default node groups that is attached to all node groups |
| <a name="output_default_ssh_key_pub"></a> [default\_ssh\_key\_pub](#output\_default\_ssh\_key\_pub) | Default node groups that is attached to all node groups |
| <a name="output_external_v4_endpoint"></a> [external\_v4\_endpoint](#output\_external\_v4\_endpoint) | An IPv4 external network address that is assigned to the master |
| <a name="output_get_credentials_command"></a> [get\_credentials\_command](#output\_get\_credentials\_command) | Command to get kubeconfig for the cluster |
| <a name="output_internal_v4_endpoint"></a> [internal\_v4\_endpoint](#output\_internal\_v4\_endpoint) | An IPv4 internal network address that is assigned to the master |
| <a name="output_log_group_id"></a> [log\_group\_id](#output\_log\_group\_id) | ID of the Yandex Cloud Logging group |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the Yandex Cloud Logging group |
| <a name="output_node_groups"></a> [node\_groups](#output\_node\_groups) | Attributes of yandex\_node\_group resources created in cluster |
<!-- END_TF_DOCS -->

## Лицензия

Apache-2.0. Подробности в [LICENSE](https://github.com/terraform-yacloud-modules/terraform-yandex-kubernetes/blob/main/LICENSE).
