# Yandex Cloud Kubernetes Terraform module

Terraform module which creates Yandex Cloud Kubernetes resources.

## Examples

Examples codified under
the [`examples`](https://github.com/terraform-yacloud-modules/terraform-yandex-kubernetes/tree/main/examples) are intended
to give users references for how to use the module(s) as well as testing/validating changes to the source code of the
module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow
maintainers to test your changes and to keep the examples up to date for users. Thank you!

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.1.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.72.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 3.1.0 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | >= 0.72.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [tls_private_key.default_ssh_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [yandex_kubernetes_cluster.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) | resource |
| [yandex_kubernetes_node_group.node_groups](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group) | resource |
| [yandex_logging_group.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/logging_group) | resource |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_ipv4_range"></a> [cluster\_ipv4\_range](#input\_cluster\_ipv4\_range) | CIDR block. IP range for allocating pod addresses. It should not overlap with<br/>any subnet in the network the K8S cluster located in. Static routes will<br/>be set up for this CIDR blocks in node subnets | `string` | `null` | no |
| <a name="input_cluster_ipv6_range"></a> [cluster\_ipv6\_range](#input\_cluster\_ipv6\_range) | Identical to cluster\_ipv4\_range but for IPv6 protocol | `string` | `null` | no |
| <a name="input_cni_type"></a> [cni\_type](#input\_cni\_type) | Type of K8S CNI which will be used for the cluster | `string` | `"calico"` | no |
| <a name="input_description"></a> [description](#input\_description) | K8S cluster description | `string` | `""` | no |
| <a name="input_enable_oslogin"></a> [enable\_oslogin](#input\_enable\_oslogin) | Enable OS Login for node groups | `bool` | `false` | no |
| <a name="input_generate_default_ssh_key"></a> [generate\_default\_ssh\_key](#input\_generate\_default\_ssh\_key) | If true, SSH key for node groups will be generated | `bool` | `true` | no |
| <a name="input_kms_provider_key_id"></a> [kms\_provider\_key\_id](#input\_kms\_provider\_key\_id) | K8S cluster KMS key ID | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A set of labels to assign to the K8S cluster | `map(string)` | `{}` | no |
| <a name="input_master_auto_upgrade"></a> [master\_auto\_upgrade](#input\_master\_auto\_upgrade) | Boolean flag that specifies if master can be upgraded automatically | `bool` | `false` | no |
| <a name="input_master_locations"></a> [master\_locations](#input\_master\_locations) | List of locations where cluster will be created. If list contains only one<br/>location, will be created zonal cluster, if more than one -- regional | <pre>list(object({<br/>    subnet_id = string<br/>    zone      = string<br/>  }))</pre> | n/a | yes |
| <a name="input_master_logging"></a> [master\_logging](#input\_master\_logging) | Master logging | <pre>object({<br/>    enabled                    = bool<br/>    create_log_group           = optional(bool, true)<br/>    log_group_retention_period = optional(string, "168h")<br/>    log_group_id               = optional(string, "")<br/>    audit_enabled              = optional(bool, true)<br/>    kube_apiserver_enabled     = optional(bool, true)<br/>    cluster_autoscaler_enabled = optional(bool, true)<br/>    events_enabled             = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_master_maintenance_windows"></a> [master\_maintenance\_windows](#input\_master\_maintenance\_windows) | List of structures that specifies maintenance windows,<br/>  when auto update for master is allowed<br/><br/>  E.g:<pre>master_maintenance_windows = [<br/>    {<br/>      start_time = "10:00"<br/>      duration   = "5h"<br/>    }<br/>  ]</pre> | `list(map(string))` | <pre>[<br/>  {<br/>    "duration": "3h",<br/>    "start_time": "23:00"<br/>  }<br/>]</pre> | no |
| <a name="input_master_public_ip"></a> [master\_public\_ip](#input\_master\_public\_ip) | Boolean flag. When true, K8S master will have visible ipv4 address | `bool` | `true` | no |
| <a name="input_master_region"></a> [master\_region](#input\_master\_region) | Name of region where cluster will be created. Required for regional cluster,<br/>not used for zonal cluster | `string` | `null` | no |
| <a name="input_master_security_group_ids"></a> [master\_security\_group\_ids](#input\_master\_security\_group\_ids) | List of security group IDs to which the K8S cluster belongs | `set(string)` | `null` | no |
| <a name="input_master_version"></a> [master\_version](#input\_master\_version) | Version of K8S that will be used for master | `string` | `"1.30"` | no |
| <a name="input_name"></a> [name](#input\_name) | K8S cluster name | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The ID of the cluster network | `string` | `null` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | K8S node groups | <pre>map(object({<br/>    description               = optional(string, null)<br/>    labels                    = optional(map(string), null)<br/>    version                   = optional(string, null)<br/>    metadata                  = optional(map(string), {})<br/>    platform_id               = optional(string, null)<br/>    memory                    = optional(string, 2)<br/>    cores                     = optional(string, 2)<br/>    core_fraction             = optional(string, 100)<br/>    gpus                      = optional(string, null)<br/>    boot_disk_type            = optional(string, "network-hdd")<br/>    boot_disk_size            = optional(string, 100)<br/>    preemptible               = optional(bool, false)<br/>    placement_group_id        = optional(string, null)<br/>    nat                       = optional(bool, false)<br/>    security_group_ids        = optional(list(string))<br/>    network_acceleration_type = optional(string, "standard")<br/>    container_runtime_type    = optional(string, "containerd")<br/>    fixed_scale               = optional(map(string), null)<br/>    auto_scale                = optional(map(string), null)<br/>    auto_repair               = optional(bool, true)<br/>    auto_upgrade              = optional(bool, true)<br/>    maintenance_windows       = optional(list(any))<br/>    node_labels               = optional(map(string), null)<br/>    node_taints               = optional(list(string), null)<br/>    allowed_unsafe_sysctls    = optional(list(string), [])<br/>    max_expansion             = optional(string, null)<br/>    max_unavailable           = optional(string, null)<br/>    zones                     = optional(list(string), null)<br/>    subnet_ids                = optional(list(string), null)<br/>    gpu_settings              = optional(map(string), null)<br/>    container_network_mtu     = optional(number, null)<br/>    instance_name_template    = optional(string, null)<br/>    placement_policy          = optional(map(string), null)<br/>    ipv4_dns_records          = optional(list(map(string)), [])<br/>    ipv6_dns_records          = optional(list(map(string)), [])<br/>  }))</pre> | `{}` | no |
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
| <a name="input_workload_identity_federation"></a> [workload\_identity\_federation](#input\_workload\_identity\_federation) | Workload Identity Federation configuration | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
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

## License

Apache-2.0 Licensed.
See [LICENSE](https://github.com/terraform-yacloud-modules/terraform-yandex-kubernetes/blob/main/LICENSE).
