resource "yandex_kubernetes_cluster_iam_binding" "bindings" {
  for_each = var.cluster_iam_members

  cluster_id = yandex_kubernetes_cluster.main.id
  role       = each.key
  members    = each.value
}
