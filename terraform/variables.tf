variable "access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "secret_access_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

/*
Command to load vars
terraform plan -var-file="vars.tfvars"
terraform apply -var-file="vars.tfvars"
*/
