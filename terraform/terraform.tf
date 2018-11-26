terraform {
  backend "s3" {
    bucket         = "com.clintonblackburn.django-demo.terraform"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform_django_demo"
  }
}
