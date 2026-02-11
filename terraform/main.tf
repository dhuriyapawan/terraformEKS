data "aws_availability_zones" "available" {
    filter {
        name = "opt-in-status"
        values = ["opt-in-not-required"]
    }
}

resource "random_string" "suffix" {
  length = 8
  special = false
}

module "vpc"  {
    source = "terraform-aws-modules/vpc/aws"
    version =" 5.0.0"

    name ="e2ecicd-vpc-${var.environment}"
    cidr = lookup(local.vpc_cidrs, var.environment)

    azs = slice(data.aws_availability_zones.available.names, 0, 3)

    private_subnets = lookup (local.private_subnets, var.environment)
    public_subnets = lookup(local.public_subnets, var.environment)

    enable_nat_gateway = true
    single_nat_gateway = true
    enable_dns_hostnames = true
    public_subnet_tags = {
        "kubernetes.io/cluster/${local.cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }

        private_subnet_tags = {
            "kubernetes.io/cluster/${local.cluster_name}" = "shared"
            "kubernetes.io/role/internal-elb" = "1"
        }
    }
    
    #EKS cluster modules
    
    module "eks" {
        source = "terraform-aws-modules/eks/aws"
        version = "18.0.0"
    
        cluster_name = local.cluster_name
        cluster_version = "1.27"
        subnets = module.vpc.private_subnets
        vpc_id = module.vpc.vpc_id
