# ============================================================
# AIR QUALITY PROJECT: DATA PREPARATION (Windows PowerShell)
# 1. Reads the list of AURN site codes from Defra UK-AIR
# 2. Downloads each site's pre-formatted 2025 hourly file
# 3. Reshapes the wide per-site files into one long file
#    (site, date, hour, pollutant, value, status), keeping
#    NO2, O3, PM10 and PM2.5
# 4. Reads each site's Defra page for its environment type,
#    region and coordinates
# Outputs: measurements.csv, site_info.csv (loaded by air_setup.sql)
# ============================================================
$ProgressPreference = 'SilentlyContinue'   # much faster downloads
$base = "C:\Users\musta\Documents\Skill Versed - data analytics\SQL\Projects\Project 6 - Air Quality"
$raw  = Join-Path $base "raw"
New-Item -ItemType Directory -Force -Path $raw | Out-Null

# ---------- 1. Site codes ----------
$html = (Invoke-WebRequest "https://uk-air.defra.gov.uk/networks/network-info?view=aurn" -UseBasicParsing).Content
$opts = [regex]::Matches($html, '<option[^>]*value="([^"]*)"[^>]*>([^<]*)</option>')
$codes = $opts | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match '^[A-Za-z0-9]{2,6}$' } | Sort-Object -Unique
"Site codes found: $($codes.Count)"
$opts | ForEach-Object { [pscustomobject]@{ site_code = $_.Groups[1].Value; site_name = $_.Groups[2].Value.Trim() } } |
    Export-Csv (Join-Path $base "sites.csv") -NoTypeInformation -Encoding UTF8

# ---------- 2. Download 2025 files ----------
$ok = 0; $missing = @()
foreach ($c in $codes) {
    $url = "https://uk-air.defra.gov.uk/datastore/data_files/site_data/${c}_2025.csv?v=1"
    $out = Join-Path $raw "${c}_2025.csv"
    try   { Invoke-WebRequest $url -OutFile $out -UseBasicParsing; $ok++ }
    catch { $missing += $c }
    Start-Sleep -Milliseconds 300
}
"Downloaded $ok files. No 2025 file for: $($missing -join ', ')"

# ---------- 3. Reshape measurements ----------
$want = @{
  'Nitrogen dioxide' = 'NO2'
  'Ozone'            = 'O3'
  'PM<sub>10</sub> particulate matter (Hourly measured)'  = 'PM10'
  'PM<sub>2.5</sub> particulate matter (Hourly measured)' = 'PM25'
}
$splitRx = ',(?=(?:[^"]*"[^"]*")*[^"]*$)'   # split on commas outside quotes
$w = New-Object System.IO.StreamWriter((Join-Path $base "measurements.csv"), $false, (New-Object System.Text.UTF8Encoding($false)))
$w.WriteLine("site_code,obs_date,obs_time,pollutant,value,status")
$rows = 0; $sitesUsed = 0
foreach ($file in Get-ChildItem $raw -Filter *_2025.csv) {
  $code  = $file.BaseName -replace '_2025$',''
  $lines = [System.IO.File]::ReadAllLines($file.FullName)
  $hdrIdx = -1
  for ($k = 0; $k -lt [Math]::Min(10, $lines.Count); $k++) { if ($lines[$k].StartsWith('Date,time')) { $hdrIdx = $k; break } }
  if ($hdrIdx -lt 0) { "No header row in $($file.Name)"; continue }
  $hdr  = [regex]::Split($lines[$hdrIdx], $splitRx) | ForEach-Object { $_.Trim('"') }
  $cols = @()   # each pollutant = value, status, unit columns
  for ($i = 2; $i -lt $hdr.Count; $i += 3) { if ($want.ContainsKey($hdr[$i])) { $cols += ,@($i, $want[$hdr[$i]]) } }
  if ($cols.Count -eq 0) { continue }
  $sitesUsed++
  for ($r = $hdrIdx + 1; $r -lt $lines.Count; $r++) {
    $f = $lines[$r].Split(',')
    if ($f.Count -lt 3) { continue }
    foreach ($c in $cols) {
      $v = $f[$c[0]]
      if ($v -ne '' -and $v -ne 'No data') {
        $w.WriteLine("$code,$($f[0]),$($f[1]),$($c[1]),$v,$($f[$c[0]+1])"); $rows++
      }
    }
  }
}
$w.Close()
"Measurements: $rows rows from $sitesUsed sites"

# ---------- 4. Site details ----------
$sites = Import-Csv (Join-Path $base "sites.csv")
$have  = (Get-ChildItem $raw -Filter *_2025.csv).BaseName -replace '_2025$',''
$info = foreach ($s in $sites | Where-Object { $have -contains $_.site_code }) {
  try {
    $h = (Invoke-WebRequest "https://uk-air.defra.gov.uk/networks/site-info?site_id=$($s.site_code)" -UseBasicParsing).Content
    $t = ($h -replace '<[^>]+>','|') -replace '&nbsp;',' '
    $env = if ($t -match 'Environment Type:[\s|]*([^|]+)') { $matches[1].Trim() } else { '' }
    $reg = if ($t -match 'Government Region:[\s|]*([^|]+)') { $matches[1].Trim() } else { '' }
    $lat = ''; $lon = ''
    if ($t -match 'Latitude[^|]*?[\s|]*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)') { $lat = $matches[1]; $lon = $matches[2] }
  } catch { $env = ''; $reg = ''; $lat = ''; $lon = '' }
  [pscustomobject]@{ site_code=$s.site_code; site_name=$s.site_name; environment_type=$env; region=$reg; latitude=$lat; longitude=$lon }
  Start-Sleep -Milliseconds 300
}
$info | Export-Csv (Join-Path $base "site_info.csv") -NoTypeInformation -Encoding UTF8
"Site info rows: $($info.Count)"
