module "network" {
  source   = "../../modules/network"
  name     = "dev"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]
}
