output "func_app_reg_client_id" {
  value = azuread_application.func_app_entra_appreg.client_id
}
output "func_app_reg_client_secret" {
  value     = azuread_application_password.func_app_entra_appreg_secret.value
  sensitive = true
}
