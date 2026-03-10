# Azure Storage Account to support the Function App
resource "azurerm_storage_account" "func_sa" {
  name                     = "${var.workload_nickname}sademo"
  resource_group_name      = var.resource_group.name
  location                 = var.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Azure App Service Plan to support the Function App
resource "azurerm_service_plan" "func_plan" {
  name                = "${var.workload_nickname}-plan-demo"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Current logged-in Azure state
data "azurerm_client_config" "current_config" {}
# Azure App Service function app on Linux authored in PowerShell
resource "azurerm_linux_function_app" "ps_func" {
  name                       = var.function_app_name
  resource_group_name        = var.resource_group.name
  location                   = var.resource_group.location
  service_plan_id            = azurerm_service_plan.func_plan.id
  storage_account_name       = azurerm_storage_account.func_sa.name
  storage_account_access_key = azurerm_storage_account.func_sa.primary_access_key
  identity {
    type = "SystemAssigned"
  }
  functions_extension_version = "~4"
  site_config {
    application_stack {
      powershell_core_version = "7.4"
    }
  }
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    unauthenticated_action = "RedirectToLoginPage"
    default_provider       = "azureactivedirectory"
    active_directory_v2 {
      client_id                  = var.func_entra_appreg_client_id
      tenant_auth_endpoint       = "https://login.microsoftonline.com/${data.azurerm_client_config.current_config.tenant_id}/v2.0"
      client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
      allowed_audiences          = ["api://${var.func_entra_appreg_client_id}"]
    }
    login {
      token_store_enabled = true
    }
  }
  app_settings = {
    MICROSOFT_PROVIDER_AUTHENTICATION_SECRET = var.func_entra_appreg_client_secret
    ENTRA_CLIENT_ID                          = var.func_entra_appreg_client_id
    ENTRA_TENANT_ID                          = data.azurerm_client_config.current_config.tenant_id
  }
}
