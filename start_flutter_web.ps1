# Build and serve the Flutter web app on port 5000
# Run from anywhere: .\start_flutter_web.ps1
Set-Location "$PSScriptRoot\frontend_flutter\disaster_resilience_ai"
flutter build web
python -m http.server 5000 --directory build\web
