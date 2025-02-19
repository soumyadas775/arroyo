

# Security group to allow SSH access to EC2
resource "aws_security_group" "ec2_security_group" {
  name        = "allow-ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
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

# IAM Role and Policy for EC2 to allow pulling images from ECR
resource "aws_iam_role" "ec2_role" {
  name               = "ec2_role_for_docker"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_access_policy" {
  name        = "ecr_access_policy"
  description = "Allow EC2 instance to pull Docker images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer"
        ]
        Effect    = "Allow"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_access_policy" {
  policy_arn = aws_iam_policy.ecr_access_policy.arn
  role       = aws_iam_role.ec2_role.name
}

# EC2 instance (Compute Service with Linux OS)
resource "aws_instance" "compute_service" {
  ami           = "ami-09a9858973b288bdd"  
  instance_type = "t3.micro"
  key_name      = "arroyo"
  security_groups = [aws_security_group.ec2_security_group.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  # User data to install Docker, authenticate with ECR, and run the Docker image
  user_data = <<-EOF
                #!/bin/bash
                # Install Docker
                yum update -y
                yum install -y docker
                service docker start
                systemctl enable docker

                # Login to AWS ECR
                $(aws ecr get-login --no-include-email --region us-east-1)

                # Pull the Docker image from ECR and run it
                docker run -d -p 80:80 <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/my-docker-repo:latest
                EOF

  # Tag for the instance
  tags = {
    Name = "DockerHostInstance"
  }
}

# IAM Instance Profile to associate the EC2 instance with the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile_for_docker"
  role = aws_iam_role.ec2_role.name
}


# RDS PostgreSQL database service
resource "aws_db_instance" "database_service" {
  identifier        = "orroyo-database"
  engine            = "postgres"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  username          = "soumya"
  password          = "password"
  db_name           = "orroyo"
  publicly_accessible = true

  tags = {
    Name = "MyDatabaseInstance"
  }
}
