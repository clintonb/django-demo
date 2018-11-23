// NOTE: These should be in terraform.tfvars, which should be kept secret.
// TODO Add `terraform fmt -diff=true -check` to Travis
variable "db_username" {}
variable "db_password" {}
variable "secret_key" {}

module "application_cluster" "django-demo-production" {
  source = "./application_cluster"

  application_name = "django-demo"
  db_name          = "djangodemo"
  environment      = "production"
  db_username      = "${var.db_username}"
  db_password      = "${var.db_password}"
  secret_key       = "${var.secret_key}"
}
