variable "resource_group" {
  description = "Parent resource group parameters"
  type = object({
    id       = string
    name     = string
    location = string
  })
}

variable "workload_nickname" {
  type = string
}

variable "function_app_name" {
  type = string
}

variable "func_entra_appreg_client_id" {
  type = string
}

variable "func_entra_appreg_client_secret" {
  type      = string
  sensitive = true
}
