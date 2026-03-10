using namespace System.Net

param($Request, $TriggerMetadata)

# Short-circuit response content if login not making it to backend
if (-not $adoToken) {
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
