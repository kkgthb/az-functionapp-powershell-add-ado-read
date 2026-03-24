using namespace System.Net

param($Request, $TriggerMetadata)

# Short-circuit response content if login not making it to backend (note:  currently failing and we are hitting the 401-out)
$userAccessToken = $Request.Headers["X-MS-TOKEN-AAD-ACCESS-TOKEN"]
if (-not $userAccessToken) {
    Push-OutputBinding `
        -Name 'Response' `
        -Value ( `
            [HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::Unauthorized
            ContentType = "text/plain"
            Body        = "No EasyAuth access token found. Are you signed in?"
        } `
    )
    return
}

# Try an OBO flow
$tenantId = $env:ENTRA_TENANT_ID
$clientId = $env:ENTRA_CLIENT_ID
$clientSecret = $env:MICROSOFT_PROVIDER_AUTHENTICATION_SECRET
$oboParams = @{
    Uri    = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    Method = "Post"
    Body   = @{
        grant_type          = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        scope               = "openid profile email"
        requested_token_use = "on_behalf_of"
        client_id           = $clientId
        client_secret       = $clientSecret
        assertion           = $userAccessToken
    }
}
try {
    $tokenResponse = Invoke-RestMethod @oboParams
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadGateway
            Body       = "OBO token exchange failed: $_"
        })
    return
}
$adoToken = $tokenResponse.access_token

# Say hello if we made it this far
Push-OutputBinding `
    -Name 'Response' `
    -Value ( `
        [HttpResponseContext]@{
        StatusCode  = [HttpStatusCode]::OK
        ContentType = "text/plain"
        Body        = "Hello, world!"
    } `
)
