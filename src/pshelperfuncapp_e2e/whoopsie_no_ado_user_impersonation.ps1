# Pull function app name and app registration client ID from Terraform state
$tfstate_file = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', '.prereqs', 'AA-tf', 'terraform.tfstate'))
$azure_function_app_name = (jq -r '.resources[] | select(.module=="module.web.module.funcapp" and .type=="azurerm_linux_function_app" and .name=="ps_func") | .instances[0].attributes.name' $tfstate_file)
$clientId = (jq -r '.resources[] | select(.module=="module.web.module.entra" and .type=="azuread_application" and .name=="func_app_entra_appreg") | .instances[0].attributes.client_id' $tfstate_file)
$tenantId = az account show --query 'tenantId' --output 'tsv'

$browser_ready_url = 'https://login.microsoftonline.com/'
$browser_ready_url += $tenantId
$browser_ready_url += "/oauth2/v2.0/authorize?client_id=$clientId"
$browser_ready_url += '&response_type=code'
$browser_ready_url += "&redirect_uri=https://azure_function_app_name.azurewebsites.net/.auth/login/aad/callback"
$browser_ready_url += '&response_mode=query'
$browser_ready_url += '&scope=openid profile email 499b84ac-1321-427f-aa17-267ca6975798/user_impersonation'
$browser_ready_url += '&prompt=consent'

Start-Process $browser_ready_url

# Bummer.
# As soon as I put " 499b84ac-1321-427f-aa17-267ca6975798/user_impersonation" 
# into the list, 
# If I try to consent using the browser, 
# given the Entra tenant that I happen to be working in 
# while I make this demo, I get...
# "AADSTS90094:  An administrator of TENANT_NAME_HERE has set a policy 
# that prevents you from granting ENTRA_APP_REG_DISPLAY_NAME_HERE 
# the permissions it is requesting. 
# Contact an administrator of TENANT_NAME_HERE who can 
# grant permissions to this application on your behalf."
