module "network" {
  source   = "../../modules/network"
  name     = "dev"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]
}

module "cluster" {
  source       = "../../modules/cluster"
  cluster_name = "dev"
  worker_count = 1
}

module "app" {
  source    = "../../modules/app"
  namespace = "demo"
  app_name  = "web"
  image     = "nginx:1.27-alpine"
  replicas  = 2

  depends_on = [module.cluster]
}
