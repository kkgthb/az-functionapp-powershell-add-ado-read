module "entra" {
  source = "./entra"
  providers = {
    azuread = azuread
  }
  workload_nickname = var.workload_nickname
  function_app_name = local.function_app_name
}

module "funcapp" {
  source     = "./funcapp"
  depends_on = [module.entra]
  providers = {
    azurerm = azurerm
  }
  resource_group                  = var.resource_group
  workload_nickname               = var.workload_nickname
  function_app_name               = local.function_app_name
  func_entra_appreg_client_id     = module.entra.func_app_reg_client_id
  func_entra_appreg_client_secret = module.entra.func_app_reg_client_secret
}
