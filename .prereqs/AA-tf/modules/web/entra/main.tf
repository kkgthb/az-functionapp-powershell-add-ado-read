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
  api {
    requested_access_token_version = 2
    # ".default" means "all scopes defined on this resource."  So let's make sure we have at least one defined.
    oauth2_permission_scope {
      admin_consent_description  = "Makes CLIs, IDEs, etc. easier."
      admin_consent_display_name = "Log into this app"
      id                         = uuidv5(data.azuread_client_config.current_config.tenant_id, "Identifier.Use.Scope") # deterministic UUID for idempotence
      type                       = "Admin"
      value                      = "Identifier.Use.Scope"
      enabled                    = true
      user_consent_description   = "Makes CLIs, IDEs, etc. easier."
      user_consent_display_name  = "Log into this app"
    }
  }
}

# Give it an explicit identifier URL
resource "azuread_application_identifier_uri" "func_app_entra_appreg_uri" {
  application_id = azuread_application.func_app_entra_appreg.id
  identifier_uri = "api://${azuread_application.func_app_entra_appreg.client_id}"
}

# TODO:  eliminate if doing a real project:  Preauthorize testing via the Azure CLI, just for funsies.
# Without this, you get error messages in hidden-behind-other-windows-on-your-desktop popups 
# that say stuff like:
# "AADSTS650057: Invalid resource. The client has requested access to a resource which 
#  is not listed in the requested permissions in the client's application registration. 
#  No valid resources listed in app reg. 04b07795-8ddb-461a-bbee-02f9e1bf7b46(Microsoft Azure CLI)"
# when you try to run 
# "az login --tenant 'tenant_id_here' --scope 'api://client_id_here/Identifier.Use.Scope' --allow-no-subscriptions" 
# once so that you can stop getting "ERROR: V2Error: invalid_resource AADSTS500011" 
# issues complaining that the "api://client_id_here" principal name doesn't exist in the tenant 
# when you try to run 
# "az account get-access-token --resource "api://client_id_here" --query 'accessToken' --output 'tsv'"
# (You should only have to logout-login this weird way once.  Then you can logout-login again and it should "just work."
# In fact, it might "just work" with any old logout-login; I haven't quite tried.)
data "azuread_application" "func_app_entra_appreg_dataversion" {
  client_id = azuread_application.func_app_entra_appreg.client_id
}
locals {
  identifier_use_scope_id = data.azuread_application.func_app_entra_appreg_dataversion.oauth2_permission_scope_ids["Identifier.Use.Scope"]
}
resource "azuread_application_pre_authorized" "appreg_preauth_azcli" {
  application_id       = azuread_application.func_app_entra_appreg.id
  authorized_client_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46" # Azure CLI well-known client ID; Azure PowerShell would be 1950a258-227b-4e31-a9cf-717495945fc2
  permission_ids       = [local.identifier_use_scope_id]
}

# Entra service principal for this Entra App Registration
resource "azuread_service_principal" "func_app_entra_sp" {
  client_id = azuread_application.func_app_entra_appreg.client_id
  owners    = [data.azuread_client_config.current_config.object_id]
}

# Associated secret that our Function App can use with this Entra App Registration
resource "azuread_application_password" "func_app_entra_appreg_secret" {
  application_id = azuread_application.func_app_entra_appreg.id
  display_name   = "easyauth-secret"
  end_date       = "2099-01-01T00:00:00Z"
}
