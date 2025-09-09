Param(
  [switch]$Integration
)

Write-Host "Running Flutter tests..." -ForegroundColor Cyan
flutter test --coverage

if ($Integration) {
  Write-Host "Running integration tests..." -ForegroundColor Cyan
  flutter test integration_test
}

Write-Host "Coverage lcov at coverage/lcov.info" -ForegroundColor Green
