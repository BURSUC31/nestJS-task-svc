provider "aws" {
  region = "eu-central-1"
}


resource "aws_db_instance" "postgres_db" {
  allocated_storage   = 5
  engine              = "postgres"
  engine_version      = "16.3"
  instance_class      = "db.t3.micro"
  username            = "postgres"
  password            = "SW&K7OSS^RY^"
  publicly_accessible = true
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

resource "terraform_data" "upload_app_bundle" {
  provisioner "local-exec" {
    command = "aws s3 cp ./app-version.zip s3://${aws_s3_bucket.app_bucket.bucket}/app-version.zip"
  }
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

resource "aws_elastic_beanstalk_application" "dmt_app" {
  name        = "production-dimi-node"
  description = "describe-my-beanstalk-app"
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-app-bucket-nestjs"
  lifecycle {
    create_before_destroy = true
  }
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
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.elastic_beanstalk_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = aws_db_instance.postgres_db.endpoint
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
    value     = "postgres"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JWT_SECRET"
    value     = "fF1t=;cOSI[l"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "TYPEORM_SYNC"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NodeCommand"
    value     = "yarn start"
  }


}



output "eb_environment_url" {
  value = aws_elastic_beanstalk_environment.production.endpoint_url
}

output "postgres_db_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}
