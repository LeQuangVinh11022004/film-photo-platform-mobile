<#
  Test tat ca API ma project Flutter dang goi va ghi log RIENG cho tung API.
  Chay:  powershell -ExecutionPolicy Bypass -File tools\api_test\run_api_tests.ps1
  Tuy chon: -BaseUrl <url>  -OutDir <thu muc log>
  Log: test_logs\api\<yyyyMMdd_HHmmss>\NN_<ten>.log  +  SUMMARY.md
#>
param(
  [string]$BaseUrl = "https://filmbooking-api-h7bghwcydwb8eecn.japaneast-01.azurewebsites.net",
  [string]$OutDir = ""
)

$ErrorActionPreference = "Continue"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
if (-not $OutDir) { $OutDir = Join-Path $root "test_logs\api\$stamp" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$script:results = @()
$script:index = 0
$script:token = $null

function Mask([string]$s) {
  if ($script:token) { $s = $s.Replace($script:token, "<JWT_TOKEN>") }
  return $s
}

function Invoke-ApiTest {
  param(
    [string]$Name, [string]$Method, [string]$Path,
    $Body = $null, [bool]$Auth = $false, [int[]]$Expect = @(200),
    [string]$Note = "", [string]$UsedBy = ""
  )
  $script:index++
  $num = "{0:D2}" -f $script:index
  $safe = ($Name -replace '[^A-Za-z0-9_]+', '_')
  $logFile = Join-Path $OutDir "${num}_${safe}.log"

  $headers = @{}
  if ($Auth -and $script:token) { $headers["Authorization"] = "Bearer $($script:token)" }
  $bodyJson = $null
  if ($null -ne $Body) { $bodyJson = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 8 } }

  $url = "$BaseUrl$Path"
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $status = 0; $content = ""; $respHeaders = ""; $err = ""
  try {
    $p = @{ Uri = $url; Method = $Method; Headers = $headers; UseBasicParsing = $true; TimeoutSec = 60 }
    if ($bodyJson) { $p["Body"] = $bodyJson; $p["ContentType"] = "application/json" }
    $r = Invoke-WebRequest @p
    $status = [int]$r.StatusCode; $content = $r.Content
    $respHeaders = ($r.Headers.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "`n"
  } catch {
    $ex = $_.Exception
    if ($ex.Response) {
      $status = [int]$ex.Response.StatusCode
      try { $content = (New-Object IO.StreamReader($ex.Response.GetResponseStream())).ReadToEnd() } catch {}
      try { $respHeaders = ($ex.Response.Headers.AllKeys | ForEach-Object { "${_}: $($ex.Response.Headers[$_])" }) -join "`n" } catch {}
    } else { $err = $ex.Message }
  }
  $sw.Stop()

  $pass = $Expect -contains $status
  $verdict = if ($pass) { "PASS" } elseif ($status -eq 0) { "ERROR" } else { "FAIL" }

  $pretty = $content
  try { if ($content) { $pretty = ($content | ConvertFrom-Json | ConvertTo-Json -Depth 10) } } catch {}

  $log = @"
==================== API TEST LOG ====================
Name      : $Name
Time      : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Result    : $verdict   (expected: $($Expect -join ' or '), actual: $status)
Duration  : $($sw.ElapsedMilliseconds) ms
Used by   : $UsedBy
Note      : $Note

---------------------- REQUEST ----------------------
$Method $url
Auth      : $(if ($Auth) { "Bearer <JWT_TOKEN>" } else { "none" })
Body      :
$(Mask $bodyJson)

---------------------- RESPONSE ---------------------
HTTP $status
$(if ($err) { "Network error: $err" })
Headers:
$respHeaders

Body:
$(Mask $pretty)
=======================================================
"@
  Set-Content -Path $logFile -Value $log -Encoding UTF8

  $script:results += [pscustomobject]@{
    No = $num; Name = $Name; Method = $Method; Path = $Path; Status = $status
    Expected = ($Expect -join "/"); Verdict = $verdict; Ms = $sw.ElapsedMilliseconds
    UsedBy = $UsedBy; Note = $Note; Log = "${num}_${safe}.log"
  }
  $color = switch ($verdict) { "PASS" { "Green" } "FAIL" { "Red" } default { "Yellow" } }
  Write-Host ("[{0}] {1,-5} {2,-45} HTTP {3}" -f $num, $verdict, $Name, $status) -ForegroundColor $color
  if ($content) { try { return ($content | ConvertFrom-Json) } catch { return $null } }
  return $null
}

Write-Host "Base URL: $BaseUrl"
Write-Host "Log dir : $OutDir`n"

# ---------- AUTH ----------
$email = "apitest_$stamp@example.com"
$pass = "Test@123456"
$guid = [guid]::NewGuid().ToString()

Invoke-ApiTest "Auth_Register_Photographer" POST "/api/auth/register/photographer" `
  @{ fullName = "API Tester"; email = $email; password = $pass } -Expect 201 `
  -UsedBy "auth_service.dart register()" | Out-Null
Invoke-ApiTest "Auth_Register_Duplicate_Email" POST "/api/auth/register/photographer" `
  @{ fullName = "API Tester"; email = $email; password = $pass } -Expect 409 `
  -Note "App xu ly 409 = email da ton tai" -UsedBy "auth_service.dart register()" | Out-Null
$login = Invoke-ApiTest "Auth_Login_OK" POST "/api/auth/login" `
  @{ email = $email; password = $pass } -Expect 200 -UsedBy "auth_service.dart login()"
if ($login -and $login.token) { $script:token = $login.token }
Invoke-ApiTest "Auth_Login_WrongPassword" POST "/api/auth/login" `
  @{ email = $email; password = "wrong_pass" } -Expect 401 -UsedBy "auth_service.dart login()" | Out-Null

# ---------- BROWSE ----------
Invoke-ApiTest "Photographer_Studios_NoToken" GET "/api/photographer/studios" -Expect 401 `
  -Note "Khong co token phai bi chan" | Out-Null
$studios = Invoke-ApiTest "Photographer_Studios" GET "/api/photographer/studios" -Auth $true `
  -UsedBy "home_screen.dart, item_list_screen.dart -> getStudios()"
$darkrooms = Invoke-ApiTest "Photographer_Darkrooms" GET "/api/photographer/darkrooms" -Auth $true `
  -UsedBy "home_screen.dart, item_list_screen.dart -> getDarkrooms()"
$from = (Get-Date).ToString("yyyy-MM-dd"); $to = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
Invoke-ApiTest "Photographer_Studios_DateFilter" GET "/api/photographer/studios?fromDate=$from&toDate=$to" -Auth $true `
  -UsedBy "item_list_screen.dart (loc theo ngay)" | Out-Null

$all = @(); if ($studios) { $all += $studios }; if ($darkrooms) { $all += $darkrooms }
$space = $all | Where-Object { $_.availableSlots.Count -gt 0 } | Select-Object -First 1
$spaceId = if ($space) { $space.resourceId } else { $guid }
$slotId = if ($space) { $space.availableSlots[0].availabilityId } else { $guid }
if (-not $space) { Write-Host "  (!) Khong co studio/darkroom nao co slot -> cac buoc booking dung GUID gia" -ForegroundColor Yellow }

# Anh
if ($space -and $space.images.Count -gt 0) {
  Invoke-ApiTest "Static_Image_Upload" GET $space.images[0].imageUrl -Expect 200 `
    -Note "Anh tuong doi /uploads/... duoc app noi voi BaseUrl (image_utils.dart)" -UsedBy "SafeNetworkImage" | Out-Null
}

Invoke-ApiTest "Photographer_Space_Availability" GET "/api/photographer/spaces/$spaceId/availability?fromDate=$from&toDate=$to" -Auth $true `
  -Note "Response dung key availableDate (model Flutter dang doc 'date')" -UsedBy "booking_api_service.dart getAvailableSlots()" | Out-Null

# ---------- BOOKING ----------
Invoke-ApiTest "Photographer_Bookings_List" GET "/api/photographer/bookings?page=1&pageSize=20" -Auth $true `
  -Note "Response dung totalItems (model Flutter dang doc 'totalCount')" -UsedBy "getMyBookings() - chua noi vao UI" | Out-Null

$bk = Invoke-ApiTest "Photographer_Booking_Create" POST "/api/photographer/bookings" `
  @{ availabilityId = $slotId; packageId = $null; equipmentIds = @() } -Auth $true -Expect 201 `
  -UsedBy "booking_flow_screen.dart _submitBooking()"
$bookingId = if ($bk -and $bk.bookingId) { $bk.bookingId } else { $guid }
Invoke-ApiTest "Photographer_Booking_Create_BadSlot" POST "/api/photographer/bookings" `
  @{ availabilityId = $guid; packageId = $null; equipmentIds = @() } -Auth $true -Expect 409 `
  -Note "Slot khong ton tai" | Out-Null
Invoke-ApiTest "Photographer_Booking_Detail" GET "/api/photographer/bookings/$bookingId" -Auth $true `
  -UsedBy "getBookingDetail() - chua noi vao UI" | Out-Null

# ---------- PAYMENT ----------
$dep = Invoke-ApiTest "Payment_DepositPayment_VNPAY" POST "/api/photographer/bookings/$bookingId/deposit-payment" `
  @{ paymentMethod = "VNPAY" } -Auth $true -Expect 200 `
  -Note "API thanh toan CHUAN. Tra paymentUrl VNPay sandbox. App chua goi payDeposit()" -UsedBy "booking_api_service.dart payDeposit() (khong duoc UI goi)"
if ($dep -and $dep.paymentUrl) { Write-Host "      paymentUrl: $($dep.paymentUrl.Substring(0,[Math]::Min(90,$dep.paymentUrl.Length)))..." }
Invoke-ApiTest "Payment_DepositPayment_MOMO" POST "/api/photographer/bookings/$bookingId/deposit-payment" `
  @{ paymentMethod = "MOMO" } -Auth $true -Expect 400 `
  -Note "BE chi ho tro VNPAY (UI van hien MoMo)" | Out-Null
Invoke-ApiTest "Payment_DepositPayment_VIETQR" POST "/api/photographer/bookings/$bookingId/deposit-payment" `
  @{ paymentMethod = "VIETQR" } -Auth $true -Expect 400 `
  -Note "BE chi ho tro VNPAY (UI van hien VietQR)" | Out-Null
Invoke-ApiTest "Payment_DepositPayment_FakeBookingId" POST "/api/photographer/bookings/BK-123456/deposit-payment" `
  @{ paymentMethod = "VNPAY" } -Auth $true -Expect 404 `
  -Note "App tao ma gia BK-xxxx khi dat phong loi -> thanh toan se 404" | Out-Null

Invoke-ApiTest "Payment_Create_VNPAY_AppCalls" POST "/api/payments/vnpay/create" `
  @{ bookingId = $bookingId; amount = 150000 } -Auth $true -Expect 200, 201 `
  -Note "Endpoint KHONG ton tai tren BE (404) nhung app dang goi" -UsedBy "payment_api_service.dart createPaymentUrl()" | Out-Null
Invoke-ApiTest "Payment_Create_MOMO_AppCalls" POST "/api/payments/momo/create" `
  @{ bookingId = $bookingId; amount = 150000 } -Auth $true -Expect 200, 201 `
  -Note "Endpoint KHONG ton tai tren BE" -UsedBy "payment_api_service.dart createPaymentUrl()" | Out-Null
Invoke-ApiTest "Payment_VNPay_Return_AppFakeParams" GET "/api/payments/vnpay/return?vnp_Amount=15000000&vnp_BankCode=NCB&vnp_OrderInfo=Test&vnp_ResponseCode=00&vnp_TransactionNo=123456&vnp_TxnRef=$bookingId" -Expect 200 `
  -Note "App gui tham so gia khong co vnp_SecureHash -> BE tu choi (400)" -UsedBy "payment_api_service.dart verifyVnpayReturn()" | Out-Null
Invoke-ApiTest "Payment_MoMo_Return_AppFakeParams" GET "/api/payments/momo/return?PartnerCode=MOMO&OrderId=$bookingId&ResultCode=0&Signature=dummy_momo_signature" -Expect 200 `
  -Note "Route MoMo da bi go khoi BE" -UsedBy "payment_api_service.dart verifyMomoReturn()" | Out-Null
Invoke-ApiTest "Payment_VNPay_IPN" GET "/api/payments/vnpay/ipn?vnp_TxnRef=abc&vnp_ResponseCode=00&vnp_SecureHash=bad" -Expect 200 `
  -Note "Server-to-server cua VNPay, app khong goi. RspCode 99 la binh thuong" | Out-Null

# ---------- CANCEL ----------
Invoke-ApiTest "Photographer_Booking_Cancel" PATCH "/api/photographer/bookings/$bookingId/cancel" -Auth $true -Expect 204 `
  -UsedBy "cancelBooking() - chua noi vao UI" | Out-Null
Invoke-ApiTest "Photographer_Booking_Cancel_NotFound" PATCH "/api/photographer/bookings/$guid/cancel" -Auth $true -Expect 404 | Out-Null

# ---------- AI ----------
Invoke-ApiTest "AI_Photography_Guide" POST "/api/ai/photography-guide" `
  @{ theme = "Chan dung vintage"; location = "Studio"; availableLight = "Anh sang cua so"; equipment = "May film 35mm"; experienceLevel = "Beginner" } `
  -Auth $true -Expect 200 -UsedBy "ai_assistant_screen.dart, home_screen.dart -> getPhotographyGuide()" | Out-Null

# ---------- SUMMARY ----------
$pass = ($results | Where-Object Verdict -eq "PASS").Count
$fail = ($results | Where-Object Verdict -ne "PASS").Count
$md = @()
$md += "# API Test Summary"
$md += ""
$md += "- Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += "- Base URL: $BaseUrl"
$md += "- Test account: $email"
$md += "- **PASS: $pass / $($results.Count)**  |  FAIL/ERROR: $fail"
$md += ""
$md += "| # | Result | Method | Endpoint | HTTP | Expected | ms | Used by | Note | Log |"
$md += "|---|---|---|---|---|---|---|---|---|---|"
foreach ($r in $results) {
  $md += "| $($r.No) | $($r.Verdict) | $($r.Method) | ``$($r.Path)`` | $($r.Status) | $($r.Expected) | $($r.Ms) | $($r.UsedBy) | $($r.Note) | [$($r.Log)]($($r.Log)) |"
}
Set-Content -Path (Join-Path $OutDir "SUMMARY.md") -Value ($md -join "`n") -Encoding UTF8
$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutDir "summary.json") -Encoding UTF8

Write-Host "`nPASS $pass / $($results.Count)  |  FAIL/ERROR $fail"
Write-Host "Logs: $OutDir"
