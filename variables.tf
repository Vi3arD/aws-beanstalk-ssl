variable "name" {
  type        = string
  default     = "demo-05-14"
  description = "Application name"
}

# Network

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "use_private_subnets" {
  type    = bool
  default = true
}

variable "azs_count" {
  type        = number
  default     = 2
  description = "Number of Availability Zones to be used"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "access_key_id" {
  type    = string
  default = "1"
}

variable "secret_access_key" {
  type    = string
  default = "1"
}

variable "enable_spot" {
  type    = bool
  default = false
}

variable "spot_price" {
  type    = string
  default = "10"
}

variable "image" {
  type    = string
  default = "demo-project-1:0.0.1-SNAPSHOT"
}

variable "ports" {
  type    = list(number)
  default = [ 8080 ]
}

variable "env" {
  type    = map(string)
  default = {
  }
}

variable "enable_logging" {
  type    = bool
  default = true
}

variable "delete_logs_on_terminate" {
  type    = bool
  default = false
}

variable "logs_retention" {
  type    = number
  default = 30
}

variable "main_db_name" {
  type    = string
  default = "main"
}

variable "main_db_engine" {
  type    = string
  default = "postgres"
}

variable "main_db_engine_version" {
  type    = string
  default = "14.2"
}

variable "main_db_instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "main_db_storage" {
  type    = number
  default = 10
}

variable "main_db_user" {
  type    = string
  default = "root"
}

variable "main_db_password" {
  type  = string
  default = null
}

variable "main_db_random_password" {
  type    = bool
  default = true
}

variable "main_db_multi_az" {
  type    = bool
  default = false
}

variable "main_db_types_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql", "upgrade"]
}

variable "main_db_performance_insights_enabled" {
  type    = bool
  default = true
}

variable "main_db_performance_insights_retention_period" {
  type    = number
  default = 7
}

variable "s3_buckets" {
  type    = list(string)
  default = []
}

variable "elasticsearch" {
  type    = list(string)
  default = []
}

############################################################
# Create cert for specified domain case in AWS
############################################################
variable "hosted_zone" {
  type    = string
  default = "mydomain.org"
}

variable "san" {
  type    = set(string)
  default = ["*.mydomain.org"]
}