output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "cluster_endpoint" {
  value = module.cluster.endpoint
}

output "kubeconfig_path" {
  value = module.cluster.kubeconfig_path
}

output "app_namespace" {
  value = module.app.namespace
}
