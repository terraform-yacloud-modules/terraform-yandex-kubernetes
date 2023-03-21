terraform {
  required_version = ">= 1.3"
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    tls = {
      source = "hashicorp/tls"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}