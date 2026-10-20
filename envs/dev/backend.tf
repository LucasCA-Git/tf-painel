# Backend parcial: o bucket é injetado pelo CI com
#   terraform init -backend-config="bucket=$TF_STATE_BUCKET"
# Lock nativo do S3 (use_lockfile), sem DynamoDB — ver ADR-0002.
terraform {
  backend "s3" {
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
