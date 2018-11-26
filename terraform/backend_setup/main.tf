resource "aws_s3_bucket" "terraform" {
  bucket = "com.clintonblackburn.django-demo.terraform"

  tags {
    Name = "django-demo Terraform State Store"
  }

  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform" {
  name           = "terraform_django_demo"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
