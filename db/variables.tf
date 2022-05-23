variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "storage" {
  type = number
}

variable "user" {
  type = string
}

variable "password" {
  type = string
  default = null
}

variable "random_password" {
  type = bool
  default = true
}

variable "multi_az" {
  type = bool
  default = false
}

variable "subnet_group_name" {
  type = string
}

variable "types_cloudwatch_logs_exports" {
  type    = list(string)
  default = []
}

variable "performance_insights_enabled" {
  type = bool
}

variable "performance_insights_retention_period" {
  type    = number
}
