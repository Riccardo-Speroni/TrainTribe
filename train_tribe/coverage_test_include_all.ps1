# Run this from the root of your Dart/Flutter project
$outputFile = Join-Path (Get-Location) "test\coverage_test.dart"

# Extract package name from pubspec.yaml
$packageName = Select-String -Path "pubspec.yaml" -Pattern "^name:\s*(\S+)" | ForEach-Object {
    $_.Matches[0].Groups[1].Value
}

if ([string]::IsNullOrWhiteSpace($packageName)) {
    Write-Host "Run this script from the root of your Dart/Flutter project"
    exit 1
}

# Create/overwrite output file
@"
/// *** GENERATED FILE - ANY CHANGES WOULD BE OBSOLETE ON NEXT GENERATION *** ///
 /// Helper to test coverage for all project files
 // ignore_for_file: unused_import
"@ | Out-File -FilePath $outputFile -Encoding UTF8

# Find all .dart files under lib, excluding .g.dart and generated_plugin_registrant
Get-ChildItem -Recurse -Filter *.dart -Path lib | Where-Object {
    $_.FullName -notmatch "\.g\.dart$" -and
    $_.FullName -notmatch "generated_plugin_registrant"
} | ForEach-Object {
    $relativePath = $_.FullName.Substring((Get-Item "lib").FullName.Length)
    # Replace backslashes with forward slashes
    $relativePath = $relativePath -replace '\\','/'
    "import 'package:$packageName$relativePath';"
} | Out-File -FilePath $outputFile -Encoding UTF8 -Append

"`nvoid main() {}" | Out-File -FilePath $outputFile -Encoding UTF8 -Append
