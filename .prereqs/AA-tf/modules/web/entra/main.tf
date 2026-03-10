# Current logged-in Entra state
data "azuread_client_config" "current_config" {}

# Create an Entra App Registration to help the Funciton App with Easy Auth
resource "azuread_application" "func_app_entra_appreg" {
  display_name = "Demo-Appreg-Project-Currently-Called-${var.workload_nickname}"
  owners       = [data.azuread_client_config.current_config.object_id]
  web {
    redirect_uris = [
      "https://${var.function_app_name}.azurewebsites.net/.auth/login/aad/callback",
    ]
    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
  required_resource_access {
    # Azure DevOps
    resource_app_id = "499b84ac-1321-427f-aa17-267ca6975798" # Well-known GUID
    resource_access {
      # user_impersonation delegated scope
      id   = "ee69721e-6c3a-468f-a9ec-302d16a4c599" # Well-known GUID
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "func_app_entra_sp" {
  client_id = azuread_application.func_app_entra_appreg.client_id
  owners    = [data.azuread_client_config.current_config.object_id]
}

resource "azuread_application_password" "func_app_entra_appreg_secret" {
  application_id = azuread_application.func_app_entra_appreg.id
  display_name   = "easyauth-secret"
  end_date       = "2099-01-01T00:00:00Z"
}
