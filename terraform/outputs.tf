output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "k8s_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "container_registry_name" {
  value = azurerm_container_registry.example.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.example.login_server
}