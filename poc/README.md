# Prova de Conceito (POC) 

## Implementando o CloudFront

O Amazon CloudFront é um serviço de rede de entrega de conteúdo (CDN) criado para alta performance, segurança e conveniência do desenvolvedor.

[Veja aqui para conhecer mais do cloudfornt](https://aws.amazon.com/pt/cloudfront/)

### 1. Crie as configuraçoes do cloudfront

Crie um arquivo .tf com essas configurações

```terraform
# cloudfront.tf
module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = ["cdn.example.com"]

  comment             = "My awesome CloudFront"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "My awesome CloudFront can access"
  }

  logging_config = {
    bucket = "logs-my-cdn.s3.amazonaws.com"
  }

  origin = {
    something = {
      domain_name = "something.example.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    s3_one = {
      domain_name = "my-s3-bycket.s3.amazonaws.com"
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id           = "something"
    viewer_protocol_policy     = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3_one"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:135367859851:certificate/1032b155-22da-4ae0-9f69-e206f825458b"
    ssl_support_method  = "sni-only"
  }
}
```

## Implementando o EKS

O Amazon Elastic Kubernetes Service (EKS) é o serviço da AWS para implantar, gerenciar e dimensionar aplicativos em contêiner com Kubernetes.

[Veja aqui alguns benefícios do EKS](https://aws.amazon.com/pt/blogs/aws-brasil/16-beneficios-do-amazon-eks-para-se-considerar-quando-escolher-sua-opcao-de-deploy/#:~:text=O%20Amazon%20EKS%20permite%20instalar,provisionamento%20do%20cluster%20ou%20posteriormente).

O EKS abstrai bastante esforço quanto a HA por ser gerenciado e ter uma configuração de autoscaling simples.

Beleza, então vamos instalar um EKS com Terraform nesse post.

### 1. Crie algumas configurações de ambiente

Crie um arquivo .tf com configurações gerais. No exemplo criei um arquivo main.tf.

```terraform
# main.tf
## região que você criará os recursos:
variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

## provider que você utilizará, nesse exemplo vou estar utilizando apenas AWS
provider "aws" {
  region = var.region
}

## em qual AZ vc quer criar esse recurso, no caso estou selecionando qualquer uma disponível
data "aws_availability_zones" "available" {}
## qual será o nome do seu cluster, estou usando um sufixo apenas para evitar falhas e não tenho muita criatividade
locals {
  cluster_name = "brbernardo-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

```

### 2. Crie a VPC

Para esse exemplo vou utilizar o módulo oficial de criação de VPC da AWS e passar alguns parâmetros simples.

```terraform
# vpc.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "brbernardo-eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

```

### 3. Crie os security groups

Nesta etapa vamos criar o SG mgmt e workers.
Isso é um pré-requisito obrigatório para o funcionamento do EKS.

```terraform
# security-groups.tf
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

```

### 4. Crie as configurações de acesso ao cluster

Nesta etapa vamos basicamente criar o token de acesso ao cluster EKS utilizando o provider kubernetes.

```terraform
# kubernetes.tf
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}

```

### 5. Crie o EKS

Finalmente vamos juntar tudo e criar o .tf para criação do EKS. Todas as etapas anteriores são os requisitos mínimos para o provisionamento do EKS, porém há mais configurações que podem ser acrescentadas.

```terraform
# eks-cluster.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  vpc_id = module.vpc.vpc_id



  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      iam_role_additional_policies           = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
      update_launch_template_default_version = true
      asg_desired_capacity          = 2
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      iam_role_additional_policies           = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
      update_launch_template_default_version = true
      asg_desired_capacity          = 1
    },
  ]
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

```

### 6. Crie o outputs

O outputs.tf será importante para a configuração do kubectl posteriormente

```terraform
# outputs.tf
output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

```

## Implementando o Redshift

O Amazon Redshift usa SQL para analisar dados estruturados e semiestruturados em data warehouses, bancos de dados operacionais e data lakes, usando hardware e machine learning projetados pela AWS para oferecer a melhor performance de preço em qualquer escala.

[Veja aqui para conhecer mais do Redshift](https://aws.amazon.com/pt/redshift/)

### 1. Crie as configuraçoes do Redshift

Crie um arquivo .tf com essas configurações

```terraform
module "redshift" {
  source  = "terraform-aws-modules/redshift/aws"
  version = "~> 3.0"

  cluster_identifier      = "my-cluster"
  cluster_node_type       = "dc1.large"
  cluster_number_of_nodes = 1

  cluster_database_name   = "mydb"
  cluster_master_username = "mydbuser"
  cluster_master_password = "mySecretPassw0rd"

  # Group parameters
  wlm_json_configuration = "[{\"query_concurrency\": 5}]"

  # DB Subnet Group Inputs
  subnets = ["subnet-123456", "subnet-654321"]

  # IAM Roles
  cluster_iam_roles = ["arn:aws:iam::225367859851:role/developer"]
}
```

## Implementando o QuickSight

O Amazon QuickSight permite que todos em sua organização entendam seus dados por meio de perguntas em linguagem natural, do uso de painéis interativos ou procurando automaticamente padrões e discrepâncias com tecnologia de machine learning.

[Veja aqui para conhecer mais do QuickSight](https://aws.amazon.com/pt/quicksight/)

### 1. Crie as configuraçoes do QuickSight

Crie um arquivo .tf com essas configurações

```terraform
resource "aws_quicksight_data_source" "default" {
  data_source_id = "example-id"
  name           = "My Cool Data in S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = "my-bucket"
        key    = "path/to/manifest.json"
      }
    }
  }

  type = "S3"
}
```
Se estiver tudo certo seu diretório estará assim

```bash
poc
│   cloudfront.tf
│   eks-cluster.tf
│   kubernetes.tf
│   main.tf
│   outputs.tf
│   quicksight.tf
│   redshift.tf
│   security-groups.tf
│   vpc.tf
```

Estando tudo certo, agora é só executar os comando init e apply

```bash
$ terraform init && terraform apply -auto-approve
```

O provisionamento demora cerca de 20 minutos, então estique as pernas e tome um café.

Estando tudo certo você estara com seu EKS minimamente configurado e ativo.

Para configurar o kubectl execute esse comando

```bash

$ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

```

É isso por hoje.
Vlw flw