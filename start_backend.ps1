# Start the FastAPI backend
# Run from anywhere: .\start_backend.ps1
Set-Location "$PSScriptRoot\backend_fastapi"
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
