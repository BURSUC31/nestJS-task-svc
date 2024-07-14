provider "aws" {
  region = "eu-central-1"
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_file_name)
}

resource "aws_db_parameter_group" "postgres_parameters" {
  name        = "postgres16-parameter-group"
  family      = "postgres16"
  description = "Custom parameter group for Postgres 15"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "pending-reboot"
  }
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Security group for RDS instance"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eb_security_group.id]
  }
}


resource "aws_db_instance" "postgres_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t4g.micro"
  username             = "postgres"
  password             = var.db_password
  db_name              = "postgres"
  publicly_accessible  = true
  parameter_group_name = aws_db_parameter_group.postgres_parameters.name
  skip_final_snapshot  = true
  storage_type         = "gp2"

  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
}

resource "aws_iam_policy" "rds_access_policy" {
  name        = "RDSAccessPolicyNode"
  description = "Policy to allow access to the RDS instance"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds-db:connect"
        ],
        Resource = [
          aws_db_instance.postgres_db.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_access_policy_attachment" {
  role       = aws_iam_role.elastic_beanstalk_role.name
  policy_arn = aws_iam_policy.rds_access_policy.arn
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicyNode"
  description = "Policy to allow access to the S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::my-app-bucket-nestjs",
          "arn:aws:s3:::my-app-bucket-nestjs/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.elastic_beanstalk_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role" "elastic_beanstalk_role" {
  name = "elastic_beanstalk_role_node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_policy" {
  role       = aws_iam_role.elastic_beanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "elastic_beanstalk_instance_profile" {
  name = "elastic_beanstalk_instance_profile_node"
  role = aws_iam_role.elastic_beanstalk_role.name
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-app-bucket-nestjs"
  lifecycle {
    create_before_destroy = true
  }
}

resource "terraform_data" "upload_app_bundle" {
  provisioner "local-exec" {
    command = "aws s3 cp ./app-version.zip s3://${aws_s3_bucket.app_bucket.bucket}/app-version.zip"
  }
}


resource "aws_security_group" "eb_security_group" {
  name        = "elastic_beanstalk_sg"
  description = "Security group for Elastic Beanstalk environment"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elastic_beanstalk_application" "dmt_app" {
  name        = "production-dimi-node"
  description = "describe-my-beanstalk-app"
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.dmt_app.name
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = "app-version.zip"
  depends_on  = [terraform_data.upload_app_bundle]


  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_elastic_beanstalk_environment" "production" {
  name                = "production"
  application         = aws_elastic_beanstalk_application.dmt_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.1.6 running Node.js 20"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = aws_key_pair.ec2_key_pair.key_name
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "StickinessEnabled"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "EnhancedHealthReporting"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/health"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.elastic_beanstalk_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "5000"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_security_group.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = aws_db_instance.postgres_db.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = aws_db_instance.postgres_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = aws_db_instance.postgres_db.password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_DB_NAME"
    value     = aws_db_instance.postgres_db.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JWT_SECRET"
    value     = var.jwt_secret
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "TYPEORM_SYNC"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PORT"
    value     = "5432"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_BUCKET"
    value     = aws_s3_bucket.app_bucket.bucket
  }

  depends_on = [
    aws_elastic_beanstalk_application_version.app_version,
    aws_security_group.eb_security_group
  ]
}


# output "eb_environment_url" {
#   value = aws_elastic_beanstalk_environment.production.endpoint_url
# }


output "eb_security_group_id" {
  value = aws_elastic_beanstalk_environment.production.load_balancers

}
# output "postgres_db_endpoint" {
#   value = aws_db_instance.postgres_db.endpoint
# }

# output "eb_security_group_id" {
#   value = aws_security_group.eb_security_group.id
# }

