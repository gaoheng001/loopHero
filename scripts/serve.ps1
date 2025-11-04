Param(
  [int]$Port = 8080
)
$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "[Serve] Serving $pwd at $prefix"
while ($true) {
  $context = $listener.GetContext()
  $request = $context.Request
  $path = $request.Url.AbsolutePath.TrimStart("/")
  if ($path -eq "") { $path = "docs/game_flow.html" }
  $fullPath = Join-Path (Get-Location) $path
  if (Test-Path $fullPath) {
    try {
      $bytes = [System.IO.File]::ReadAllBytes($fullPath)
      $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
      $contentType = "text/plain"
      switch ($ext) {
        ".html" { $contentType = "text/html" }
        ".htm"  { $contentType = "text/html" }
        ".js"   { $contentType = "application/javascript" }
        ".css"  { $contentType = "text/css" }
        ".svg"  { $contentType = "image/svg+xml" }
        ".json" { $contentType = "application/json" }
      }
      $context.Response.ContentType = $contentType
      $context.Response.ContentLength64 = $bytes.Length
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      $context.Response.StatusCode = 200
    } catch {
      $context.Response.StatusCode = 500
      $errorBytes = [Text.Encoding]::UTF8.GetBytes("Server error: $_")
      $context.Response.OutputStream.Write($errorBytes, 0, $errorBytes.Length)
    }
  } else {
    $context.Response.StatusCode = 404
    $errorBytes = [Text.Encoding]::UTF8.GetBytes("Not Found: $path")
    $context.Response.OutputStream.Write($errorBytes, 0, $errorBytes.Length)
  }
  $context.Response.OutputStream.Close()
  $context.Response.Close()
}