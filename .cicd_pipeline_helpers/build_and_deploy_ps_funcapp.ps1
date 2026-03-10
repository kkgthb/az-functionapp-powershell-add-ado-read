$gitignored_directory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '.ignoreme'))
if (-not (Test-Path $gitignored_directory)) {
    New-Item -Path $gitignored_directory -ItemType Directory | Out-Null
}
$temp_zip_here = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($gitignored_directory, 'tempfuncappzip.zip'))
$func_app_src_code = [System.IO.Path]::GetFullPath("$PsScriptRoot/../src/pshelperfuncapp")
$func_app_src_code_plus_asterisk = [System.IO.Path]::Combine($func_app_src_code, '*')

Compress-Archive `
    -Path $func_app_src_code_plus_asterisk `
    -DestinationPath $temp_zip_here

$tfstate_file = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '.prereqs', 'AA-tf', 'terraform.tfstate'))
$azure_resource_group_name = (jq -r '.resources[] | select(.type=="azurerm_resource_group" and .name=="my_resource_group") | .instances[0].attributes.name' $tfstate_file)
$azure_function_app_name = (jq -r '.resources[] | select(.module=="module.web.module.funcapp" and .type=="azurerm_linux_function_app" and .name=="ps_func") | .instances[0].attributes.name' $tfstate_file)

Write-Host("Begin upload")
az functionapp deployment source config-zip `
    --subscription "$([Environment]::GetEnvironmentVariable('DEMOS_my_azure_subscription_id', 'User'))" `
    --resource-group $azure_resource_group_name `
    --name $azure_function_app_name `
    --src $temp_zip_here
Write-Host("End upload")

Remove-Item -Path $temp_zip_here