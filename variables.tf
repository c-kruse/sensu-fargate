
variable "region" {
  default = "us-west-2"
}
variable "image" {
  default = "sensu/sensu:6.6.6"
}

variable "sensu_version_tag" {
  default = "6.7.2"
}

variable "default_tags" {
  default = {
    ManagedBy = "terraform"
    CreatedBy = "ckruse"
  }
}
