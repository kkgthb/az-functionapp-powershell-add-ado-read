# profile.ps1
# This file runs once when the Function App worker starts up.
# Use it for one-time setup, e.g. connecting modules.

# Authenticate the Managed Identity for any Az module calls (not ADO OBO).
if ($env:MSI_ENDPOINT) {
    Connect-AzAccount -Identity | Out-Null
}
