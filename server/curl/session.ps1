# curl/session.ps1 — сессия curl на сущностях темы (для отчёта L5).
# Запуск из папки server/ при работающем сервере:
#   powershell -ExecutionPolicy Bypass -File curl\session.ps1
# Сценарий: register → 401 без token-а → создание → список с search=.
# Тела запросов лежат в curl/*.json (UTF-8) — так кириллица не ломается в PowerShell.
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$B = 'http://localhost:8080'
$email = "demo_$(Get-Date -Format 'HHmmss')@test.md"

function Show($cmd) { Write-Host "`n> $cmd" -ForegroundColor Cyan }

Show "curl -X POST $B/auth/register -H 'Content-Type: application/json' -d '{""email"":""$email"",""password"":""parola123"",""name"":""Ana""}'"
'{"email":"' + $email + '","password":"parola123","name":"Ana"}' | Set-Content -Encoding ascii "$env:TEMP\reg.json"
$r = curl.exe -s -w "`nHTTP %{http_code}" -X POST "$B/auth/register" -H "Content-Type: application/json" -d "@$env:TEMP\reg.json"
$r
$token = (($r -split "`n")[0] | ConvertFrom-Json).token

Show "curl -X POST $B/auth/register ... (тот же email во второй раз)"
curl.exe -s -w "`nHTTP %{http_code}" -X POST "$B/auth/register" -H "Content-Type: application/json" -d "@$env:TEMP\reg.json"

Show "curl -i $B/properties        # без token-а"
curl.exe -s -w "`nHTTP %{http_code}" "$B/properties"

Show "curl -X POST $B/properties -H 'Authorization: Bearer <token>' -d @curl/property.json"
curl.exe -s -w "`nHTTP %{http_code}" -X POST "$B/properties" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "@curl/property.json"

Show "curl -X POST $B/bookings -H 'Authorization: Bearer <token>' -d @curl/booking.json"
curl.exe -s -w "`nHTTP %{http_code}" -X POST "$B/bookings" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "@curl/booking.json"

Show "curl -X POST $B/properties -d '{""price"":-1}'   # невалидное тело"
'{"price":-1}' | Set-Content -Encoding ascii "$env:TEMP\bad.json"
curl.exe -s -w "`nHTTP %{http_code}" -X POST "$B/properties" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "@$env:TEMP\bad.json"

Show "curl -G $B/properties --data-urlencode 'search=центр' -H 'Authorization: Bearer <token>'"
curl.exe -s -w "`nHTTP %{http_code}" -G "$B/properties" --data-urlencode "search@curl/search.txt" -H "Authorization: Bearer $token"

Show "curl -G $B/properties --data-urlencode 'search=несуществующее' -H 'Authorization: Bearer <token>'"
curl.exe -s -w "`nHTTP %{http_code}" -G "$B/properties" --data-urlencode "search=zzz-none" -H "Authorization: Bearer $token"

Show "curl $B/bookings?page=1&limit=20 -H 'Authorization: Bearer <token>'"
curl.exe -s -w "`nHTTP %{http_code}" "$B/bookings?page=1&limit=20" -H "Authorization: Bearer $token"
Write-Host ""
