variable "application_name" {}

variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "environment" {}

variable "health_check_path" {
  default = "/health/"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "route_53_zone_id" {}
variable "secret_key" {}
variable "ssl_cert_arn" {}

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

  //  TODO Limit the number of retained application versions
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
    value     = "${var.instance_type}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  // Use an Application Load Balancer (ALB) instead of the default Classic ELB
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  // Use our custom path for health checks since not all projects have an active root path
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "${var.health_check_path}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "${var.health_check_path}"
  }

  // Update the ELB/ALB to terminate SSL
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = "${var.ssl_cert_arn}"
  }

  // Stream logs to Cloudwatch, and hold them for 90 days
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "90"
  }

  setting {
    namespace = "aws:elasticbeanstalk:hostmanager"
    name      = "LogPublicationControl"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }

  // Define environment variables for the application
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

// Create a DNS record at the naked domain (e.g. example.com instead of www.example.com)
// that points to the application
data "aws_elastic_beanstalk_hosted_zone" "current" {}

resource "aws_route53_record" "record" {
  zone_id = "${var.route_53_zone_id}"
  name    = ""
  type    = "A"

  alias {
    name                   = "${lower(aws_elastic_beanstalk_environment.environment.cname)}"
    zone_id                = "${data.aws_elastic_beanstalk_hosted_zone.current.id}"
    evaluate_target_health = false
  }
}
