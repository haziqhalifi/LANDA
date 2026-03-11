# Serve the admin website on port 3000
# Run from anywhere: .\start_admin.ps1
Set-Location "$PSScriptRoot"
python -m http.server 3000 --directory admin_website
