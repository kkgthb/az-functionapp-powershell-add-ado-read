# Requires the Microsoft.Graph PowerShell module
# Install-Module Microsoft.Graph -Scope CurrentUser

Connect-MgGraph # -Scopes "Directory.Read.All"

# Find the Azure DevOps service principal in your tenant
$adoSp = Get-MgServicePrincipal -Filter "appId eq '499b84ac-1321-427f-aa17-267ca6975798'"

Write-Host "`n=== ADMIN CONSENT (tenant-wide grants) ===" -ForegroundColor Cyan
$adminGrants = Get-MgOauth2PermissionGrant -All `
    -Filter "resourceId eq '$($adoSp.Id)' and consentType eq 'AllPrincipals'"

foreach ($grant in $adminGrants) {
    $clientSp = Get-MgServicePrincipal -ServicePrincipalId $grant.ClientId -All
    [PSCustomObject]@{
        DisplayName = $clientSp.DisplayName
        AppId       = $clientSp.AppId
        ClientSpId  = $grant.ClientId
        Scopes      = $grant.Scope
        ConsentType = "Admin (all users)"
    }
}

Write-Host "`n=== USER CONSENT (individual user grants) ===" -ForegroundColor Cyan
$userGrants = Get-MgOauth2PermissionGrant -All `
    -Filter "resourceId eq '$($adoSp.Id)' and consentType eq 'Principal'"

foreach ($grant in $userGrants) {
    $clientSp = Get-MgServicePrincipal -ServicePrincipalId $grant.ClientId
    $user = Get-MgUser -UserId $grant.PrincipalId -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        DisplayName = $clientSp.DisplayName
        AppId       = $clientSp.AppId
        ClientSpId  = $grant.ClientId
        Scopes      = $grant.Scope
        ConsentType = "User consent"
        UserUPN     = $user.UserPrincipalName
    }
}