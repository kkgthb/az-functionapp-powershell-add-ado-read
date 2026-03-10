# Note:  If you get a "ERROR: V2Error: invalid_resource AADSTS500011" complaining that the "api://client_id_here" 
# principal name doesn't exist in the tenant, you might need to "az logout" 
# and "az login --tenant 'tenant_id_here' --scope 'api://client_id_here/Identifier.Use.Scope' --allow-no-subscriptions"
# at least once.
# Actually, it seems that maybe specifying a scope is unnecessary, and you 
# might just need to log out and back in to clear the `get-access-token` cache or something.

# Pull function app name and app registration client ID from Terraform state
BeforeAll {
    $tfstate_file = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', '.prereqs', 'AA-tf', 'terraform.tfstate'))
    $azure_function_app_name = (jq -r '.resources[] | select(.module=="module.web.module.funcapp" and .type=="azurerm_linux_function_app" and .name=="ps_func") | .instances[0].attributes.name' $tfstate_file)
    $clientId = (jq -r '.resources[] | select(.module=="module.web.module.entra" and .type=="azuread_application" and .name=="func_app_entra_appreg") | .instances[0].attributes.client_id' $tfstate_file)

    # Get a token scoped to the EasyAuth app registration so we can call through EasyAuth
    $accessToken = az account get-access-token --resource "api://$clientId" --query 'accessToken' --output 'tsv'
    $script:authHeader = @{ Authorization = "Bearer $accessToken" }
}

Describe 'SayHello function' {
    It 'returns 200 with Hello, world!' {
        $response = Invoke-WebRequest `
            -Uri "https://$azure_function_app_name.azurewebsites.net/api/SayHello" `
            -Headers $script:authHeader `
            -UseBasicParsing

        $response.StatusCode | Should -Be 200
        $response.Content    | Should -Be 'Hello, world!'
    }
}

AfterAll {
    $script:authHeader = $null
    $accessToken = $null
}