terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- IAM Role for Loki to access S3 ---
resource "aws_iam_role" "loki_s3_role" {
  name = "loki_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "loki_s3_policy" {
  name        = "loki_s3_access_policy"
  description = "Allow Loki to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.loki_bucket.arn,
          "${aws_s3_bucket.loki_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "loki_s3_attach" {
  role       = aws_iam_role.loki_s3_role.name
  policy_arn = aws_iam_policy.loki_s3_policy.arn
}

resource "aws_iam_instance_profile" "loki_profile" {
  name = "loki_instance_profile"
  role = aws_iam_role.loki_s3_role.name
}

# --- S3 Bucket for Loki ---
resource "aws_s3_bucket" "loki_bucket" {
  bucket_prefix = "loki-storage-"
  force_destroy = true
}

# --- Security Groups ---
resource "aws_security_group" "traefik_sg" {
  name        = "traefik_sg"
  description = "Allow HTTP, HTTPS, SSH for Traefik reverse proxy"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring_sg"
  description = "Allow internal VPC access to Grafana and Loki"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # VPC only
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Grafana from VPC
  }

  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # Loki from VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow VPC access to MySQL"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # VPC only
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]  # MySQL from VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Route53 DNS ---
# Commented out - DNS now managed in Azure
# data "aws_route53_zone" "main" {
#   name = "infratestapp.pp.ua"
# }

# resource "aws_route53_record" "grafana" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "grafana.infratestapp.pp.ua"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.traefik.public_ip]  # Point to Traefik instance
# }

# --- Key Pair ---
resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key-${random_id.server_id.hex}"
  public_key = file("${path.module}/my-key.pub")
}

resource "random_id" "server_id" {
  byte_length = 4
}

# --- EC2 Instances ---
resource "aws_instance" "traefik" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name
  
  vpc_security_group_ids      = [aws_security_group.traefik_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Traefik-Instance"
  }
}

resource "aws_instance" "monitoring" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name
  
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.loki_profile.name
  associate_public_ip_address = false  # Private instance

  tags = {
    Name = "Monitoring-Instance"
  }
}

resource "aws_instance" "database" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  associate_public_ip_address = false  # Private instance

  tags = {
    Name = "Database-Instance"
  }
}

# --- Ansible Inventory Generation ---
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    traefik_ip            = aws_instance.traefik.public_ip
    traefik_private_ip    = aws_instance.traefik.private_ip
    monitoring_ip         = aws_instance.monitoring.private_ip
    monitoring_private_ip = aws_instance.monitoring.private_ip
    database_ip           = aws_instance.database.private_ip
    database_private_ip   = aws_instance.database.private_ip
    loki_bucket           = aws_s3_bucket.loki_bucket.id
    region                = var.aws_region
    private_key           = abspath("${path.module}/my-key")
  })
  filename = "${path.module}/../ansible/inventory.ini"

  lifecycle {
    ignore_changes = [content]
  }
}
