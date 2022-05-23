terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
      version = "2.8.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "3.4.0"
    }
  }
}