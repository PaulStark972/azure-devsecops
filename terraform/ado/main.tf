variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "personal_access_token" {
  type = string
}

variable "org_service_url" {
  type = string
}

provider "azuread" {
  version = "=0.7.0"

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}


provider "azuredevops" {
  version = ">= 0.0.1"

  org_service_url       = var.org_service_url
  personal_access_token = var.personal_access_token
}

resource "azuread_group" "workload" {
  name = "aadgr-workload"
}

resource "azuredevops_project" "workload" {
  project_name       = "adop-workload"

  visibility         = "private"
  
  version_control    = "Git"
  work_item_template = "Agile"

  features = {
      "testplans" = "disabled"
      "artifacts" = "disabled"
  }
}
