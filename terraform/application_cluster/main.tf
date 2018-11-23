variable "application_name" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "environment" {}
variable "secret_key" {}

resource "aws_db_instance" "database" {
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "10.5"
  instance_class            = "db.t2.micro"
  identifier                = "${var.application_name}-${var.environment}"
  final_snapshot_identifier = "${var.application_name}-${var.environment}-final"
  name                      = "${var.db_name}"
  username                  = "${var.db_username}"
  password                  = "${var.db_password}"
}

resource "aws_elastic_beanstalk_application" "application" {
  name = "${var.application_name}"

  //  TODO Service role
  //  appversion_lifecycle {
  //    service_role          = "${aws_iam_role.beanstalk_service.arn}"
  //    max_count             = 128
  //    delete_source_from_s3 = true
  //  }
}

resource "aws_elastic_beanstalk_environment" "environment" {
  name                = "${var.application_name}-${var.environment}"
  application         = "${var.application_name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.12.5 running Docker 18.06.1-ce"

  // NOTE: See https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html for more settings.
  // NOTE: The RDS settings do not work!
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  //  TODO Determine how to get around the error: unable to sign request without credentials set.
  //  setting {
  //    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
  //    name = "StreamLogs"
  //    value = "true"
  //  }
  //
  //  setting {
  //    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
  //    name = "RetentionInDays"
  //    value = "90"
  //  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECRET_KEY"
    value     = "${var.secret_key}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = "psql://${var.db_username}:${var.db_password}@${aws_db_instance.database.endpoint}/${var.db_name}"
  }
}
