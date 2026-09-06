<#
Run SQL validation queries against the LewisStores database and export outputs.
Configure the connection below before running.
#>

param(
    [string]$Server = ".\\SQLEXPRESS",
    [string]$Database = "LewisStoresDb",
    [string]$Username = "",
    [string]$Password = "",
    [string]$OutputFolder = ".\validation_results"
)

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

$validationSql = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "validation\01-data-integrity-queries.sql"
if (-not (Test-Path $validationSql)) { Write-Error "Validation SQL not found at $validationSql"; exit 1 }

# Build sqlcmd auth args
if ($Username -ne "") {
    $auth = "-U $Username -P $Password"
} else {
    $auth = "-E"
}

# Run each GO-separated batch and capture output to files
$sqlText = Get-Content $validationSql -Raw
$batches = $sqlText -split "\r?\nGO\r?\n" -ne ""
$index = 1
foreach ($batch in $batches) {
    $outFile = Join-Path $OutputFolder ("batch_{0:000}.txt" -f $index)
    Write-Host "Running batch $index -> $outFile"

    # Write batch to a temporary .sql file and execute with sqlcmd to avoid quoting issues
    $tmpSql = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "lewis_validation_batch_{0:000}.sql" -f $index)
    Set-Content -Path $tmpSql -Value $batch -Encoding utf8

    $argList = @()
    $argList += '-S'; $argList += $Server
    $argList += '-d'; $argList += $Database
    if ($Username -ne '') { $argList += '-U'; $argList += $Username; $argList += '-P'; $argList += $Password } else { $argList += '-E' }
    $argList += '-i'; $argList += $tmpSql
    $argList += '-s'; $argList += ','
    $argList += '-W'

    & sqlcmd @argList | Out-File -FilePath $outFile -Encoding utf8
    Remove-Item $tmpSql -ErrorAction SilentlyContinue
    $index++
}

Write-Host "Validation complete. Results in: $OutputFolder"
