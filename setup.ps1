# One-time setup for any new PC
# Run once: .\setup.ps1

Write-Host "=== Installing Python dependencies ===" -ForegroundColor Cyan
pip install -r "$PSScriptRoot\backend_fastapi\requirements.txt"

Write-Host "`n=== Installing ai_models package ===" -ForegroundColor Cyan
pip install -e "$PSScriptRoot\ai_models"

Write-Host "`n=== Installing Flutter dependencies ===" -ForegroundColor Cyan
Set-Location "$PSScriptRoot\frontend_flutter\disaster_resilience_ai"
flutter pub get

Write-Host "`nSetup complete! Now run:" -ForegroundColor Green
Write-Host "  Terminal 1: .\start_backend.ps1"
Write-Host "  Terminal 2: .\start_flutter_web.ps1"
Write-Host "  Terminal 3: .\start_admin.ps1"
