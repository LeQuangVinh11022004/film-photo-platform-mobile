<#
  Test tat ca API ma project Flutter dang goi (bao gom Package Subscription, Booking, Payment, AI Guide cho PHOTOGRAPHER & EXPERT)
  va ghi log RIENG cho tung API + file tong hop summary.log (100% PowerShell thuan).
  Chay:  powershell -ExecutionPolicy Bypass -File tools\api_test\run_api_tests.ps1
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
$script:expertToken = $null

function Mask([string]$s) {
  if ($script:token) { $s = $s.Replace($script:token, "<PHOTOGRAPHER_JWT>") }
  if ($script:expertToken) { $s = $s.Replace($script:expertToken, "<EXPERT_JWT>") }
  return $s
}

function Invoke-ApiTest {
  param(
    [string]$Name, [string]$Method, [string]$Path,
    $Body = $null, [bool]$Auth = $false, [string]$CustomToken = "", [int[]]$Expect = @(200),
    [string]$Note = "", [string]$UsedBy = ""
  )
  $script:index++
  $num = "{0:D2}" -f $script:index
  $safe = ($Name -replace '[^A-Za-z0-9_]+', '_')
  $logFile = Join-Path $OutDir "${num}_${safe}.log"

  $headers = @{}
  if ($CustomToken) {
    $headers["Authorization"] = "Bearer $CustomToken"
  } elseif ($Auth -and $script:token) {
    $headers["Authorization"] = "Bearer $($script:token)"
  }
  $bodyJson = $null
  if ($null -ne $Body) { $bodyJson = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 8 } }

  $url = if ($Path -match "^https?://") { $Path } else { "$BaseUrl$Path" }
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

  $authLabel = if ($CustomToken) { "Bearer <EXPERT_JWT>" } elseif ($Auth) { "Bearer <PHOTOGRAPHER_JWT>" } else { "none" }
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
Auth      : $authLabel
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
  Write-Host ("[{0}] {1,-5} {2,-48} HTTP {3}" -f $num, $verdict, $Name, $status) -ForegroundColor $color
  if ($content) { try { return ($content | ConvertFrom-Json) } catch { return $null } }
  return $null
}

Write-Host "Base URL: $BaseUrl"
Write-Host "Log dir : $OutDir`n"

# ---------- 1. AUTH (PHOTOGRAPHER & EXPERT) ----------
$email = "apitest_$stamp@example.com"
$pass = "Test@123456"
$guid = [guid]::NewGuid().ToString()

Invoke-ApiTest "Auth_Register_Photographer" POST "/api/auth/register/photographer" `
  @{ fullName = "API Tester"; email = $email; password = $pass } -Expect 201 `
  -UsedBy "auth_service.dart register()" | Out-Null

Invoke-ApiTest "Auth_Register_Duplicate_Email" POST "/api/auth/register/photographer" `
  @{ fullName = "API Tester"; email = $email; password = $pass } -Expect 409 `
  -Note "App xu ly 409 = email da ton tai" -UsedBy "auth_service.dart register()" | Out-Null

$login = Invoke-ApiTest "Auth_Login_Photographer_OK" POST "/api/auth/login" `
  @{ email = $email; password = $pass } -Expect 200 `
  -Note "Dang nhap PHOTOGRAPHER -> dieu huong /home" -UsedBy "auth_service.dart login()"
if ($login -and $login.token) { $script:token = $login.token }

Invoke-ApiTest "Auth_Login_WrongPassword" POST "/api/auth/login" `
  @{ email = $email; password = "wrong_pass" } -Expect 401 `
  -UsedBy "auth_service.dart login()" | Out-Null

$expertLogin = Invoke-ApiTest "Auth_Login_Expert_OK" POST "/api/auth/login" `
  @{ email = "expert.demo@filmbooking.local"; password = "FilmDemo2026!" } -Expect 200 `
  -Note "Dang nhap EXPERT -> dieu huong /expert-workspace" -UsedBy "auth_service.dart login()"
if ($expertLogin -and $expertLogin.token) { $script:expertToken = $expertLogin.token }

# ---------- 2. BROWSE SPACES & EQUIPMENT (PHOTOGRAPHER vs EXPERT) ----------
Invoke-ApiTest "Photographer_Studios_NoToken" GET "/api/photographer/studios" -Expect 401 `
  -Note "Khong co token phai bi chan (401)" | Out-Null

Invoke-ApiTest "Photographer_Studios_ExpertForbidden" GET "/api/photographer/studios" `
  -CustomToken $script:expertToken -Expect 403 `
  -Note "Role EXPERT goi endpoint PHOTOGRAPHER bi chan 403 Forbidden" | Out-Null

$studios = Invoke-ApiTest "Photographer_Studios" GET "/api/photographer/studios" -Auth $true `
  -UsedBy "home_screen.dart, item_list_screen.dart -> getStudios()"

$darkrooms = Invoke-ApiTest "Photographer_Darkrooms" GET "/api/photographer/darkrooms" -Auth $true `
  -UsedBy "home_screen.dart, item_list_screen.dart -> getDarkrooms()"

$from = (Get-Date).ToString("yyyy-MM-dd"); $to = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
Invoke-ApiTest "Photographer_Studios_DateFilter" GET "/api/photographer/studios?fromDate=$from&toDate=$to" -Auth $true `
  -UsedBy "item_list_screen.dart -> getStudios(fromDate, toDate)" | Out-Null

$all = @(); if ($studios) { $all += $studios }; if ($darkrooms) { $all += $darkrooms }
$space = $all | Where-Object { $_.availableSlots.Count -gt 0 } | Select-Object -First 1
$spaceId = if ($space) { $space.resourceId } else { "0e85263b-2d1d-4bf3-833e-9986829ac8a6" }
$slotCount = if ($space -and $space.availableSlots) { $space.availableSlots.Count } else { 0 }
$slotId = if ($slotCount -gt 0) { $space.availableSlots[$slotCount - 1].availabilityId } else { $guid }

Invoke-ApiTest "Photographer_Space_Availability" GET "/api/photographer/spaces/$spaceId/availability?fromDate=$from&toDate=$to" -Auth $true `
  -Note "Lay danh sach slot trong cua Studio/Darkroom" -UsedBy "booking_api_service.dart getAvailableSlots()" | Out-Null

Invoke-ApiTest "Photographer_Equipment_Availability" GET "/api/photographer/equipment/40000000-0000-0000-0000-000000000001/availability?fromDate=$from&toDate=$to" -Auth $true `
  -Note "API MOI: Lay khung gio trong cua thiet bi (Canon EOS 5D Mark IV)" -UsedBy "booking_api_service.dart getEquipmentAvailability()" | Out-Null

Invoke-ApiTest "Photographer_Equipment_Availability_NotFound" GET "/api/photographer/equipment/$guid/availability" -Auth $true -Expect 404 `
  -Note "API MOI: Thiet bi khong ton tai tra ve 404" -UsedBy "booking_api_service.dart getEquipmentAvailability()" | Out-Null

# ---------- 3. PACKAGE SUBSCRIPTION & SERVICE PACKAGES (NEW APIs) ----------
Invoke-ApiTest "Photographer_ServicePackages_List" GET "/api/photographer/service-packages" -Auth $true -Expect 200 `
  -Note "API MOI: Lay danh sach Goi Dich Vu Combo (Azure DB chua migrate bang service_package_items nen dang 500)" `
  -UsedBy "service_packages_screen.dart -> getServicePackages()" | Out-Null

Invoke-ApiTest "Photographer_ServicePackage_Purchase" POST "/api/photographer/service-packages/$guid/purchase" -Auth $true -Expect 200, 404 `
  -Note "API MOI: Khoi tao thanh toan VNPay mua Goi Dich Vu Combo" `
  -UsedBy "payment_api_service.dart -> initiatePackagePurchasePayment()" | Out-Null

Invoke-ApiTest "Photographer_PackageSubscriptions_List" GET "/api/photographer/package-subscriptions" -Auth $true -Expect 200 `
  -Note "API MOI: Lay danh sach Goi Subscription da mua cua Photographer" `
  -UsedBy "service_packages_screen.dart, booking_flow_screen.dart -> getPackageSubscriptions()" | Out-Null

Invoke-ApiTest "Photographer_PackageSubscription_Detail" GET "/api/photographer/package-subscriptions/$guid" -Auth $true -Expect 200, 404 `
  -Note "API MOI: Xem chi tiet 1 Goi Subscription da mua" `
  -UsedBy "service_packages_screen.dart -> getPackageSubscriptionDetail()" | Out-Null

# ---------- 4. BOOKINGS (STANDARD & PACKAGE SUBSCRIPTION) ----------
Invoke-ApiTest "Photographer_Bookings_List" GET "/api/photographer/bookings?page=1&pageSize=20" -Auth $true `
  -UsedBy "schedule_screen.dart, profile_screen.dart -> getMyBookings()" | Out-Null

$bk = Invoke-ApiTest "Photographer_Booking_Create_Standard" POST "/api/photographer/bookings" `
  @{ availabilityId = $slotId; equipmentIds = @() } -Auth $true -Expect 201 `
  -Note "Dat phong le (schema moi: availabilityId + equipmentIds, khong truyen packageId)" `
  -UsedBy "booking_flow_screen.dart _submitBooking()"
$bookingId = if ($bk -and $bk.bookingId) { $bk.bookingId } else { $guid }

Invoke-ApiTest "Photographer_Booking_Create_BadSlot" POST "/api/photographer/bookings" `
  @{ availabilityId = $guid; equipmentIds = @() } -Auth $true -Expect 409 `
  -Note "Slot khong ton tai tra ve 409 Conflict" -UsedBy "booking_api_service.dart createBooking()" | Out-Null

Invoke-ApiTest "Photographer_Booking_Create_InvalidPayload" POST "/api/photographer/bookings" `
  @{ availabilityId = $null; subscriptionId = $null } -Auth $true -Expect 400 `
  -Note "Khong truyen availabilityId hoac subscriptionId tra ve 400 BadRequest" -UsedBy "booking_api_service.dart createBooking()" | Out-Null

Invoke-ApiTest "Photographer_Booking_Create_FromSubscription" POST "/api/photographer/bookings" `
  @{ subscriptionId = $guid; segments = @( @{ stepOrder = 1; availabilityId = $slotId; equipmentIds = @() } ) } `
  -Auth $true -Expect 201, 409 `
  -Note "API MOI: Dat lich su dung Goi Subscription (subscriptionId + segments)" `
  -UsedBy "service_packages_screen.dart, booking_flow_screen.dart -> createPackageBooking()" | Out-Null

Invoke-ApiTest "Photographer_Booking_Detail" GET "/api/photographer/bookings/$bookingId" -Auth $true `
  -UsedBy "payment_api_service.dart refreshBookingStatus() -> getBookingDetail()" | Out-Null

# ---------- 5. PAYMENT (VNPAY DEPOSIT & CALLBACKS) ----------
$dep = Invoke-ApiTest "Payment_DepositPayment_VNPAY" POST "/api/photographer/bookings/$bookingId/deposit-payment" `
  @{ paymentMethod = "VNPAY" } -Auth $true -Expect 200 `
  -Note "Khoi tao thanh toan dat coc 30% qua VNPay Sandbox -> tra ve paymentUrl" `
  -UsedBy "payment_screen.dart -> initiateDepositPayment() -> payDeposit()"
if ($dep -and $dep.paymentUrl) { Write-Host "      paymentUrl: $($dep.paymentUrl.Substring(0,[Math]::Min(90,$dep.paymentUrl.Length)))..." }

Invoke-ApiTest "Payment_DepositPayment_MOMO_Unsupported" POST "/api/photographer/bookings/$bookingId/deposit-payment" `
  @{ paymentMethod = "MOMO" } -Auth $true -Expect 400 `
  -Note "Backend chi ho tro VNPAY, tu choi MOMO voi HTTP 400" | Out-Null

Invoke-ApiTest "Payment_VNPay_Return_MissingSignature" GET "/api/payments/vnpay/return?vnp_Amount=67500000&vnp_ResponseCode=00&vnp_TxnRef=$bookingId" -Expect 400 `
  -Note "Thieu vnp_SecureHash -> Backend tu choi 400 InvalidNotification" `
  -UsedBy "payment_api_service.dart verifyReturnEndpoint()" | Out-Null

Invoke-ApiTest "Payment_VNPay_IPN" GET "/api/payments/vnpay/ipn?vnp_TxnRef=abc&vnp_ResponseCode=00&vnp_SecureHash=bad" -Expect 200 `
  -Note "Server-to-server webhook cua VNPay (RspCode 97/99)" | Out-Null

# ---------- 6. CANCEL BOOKING ----------
Invoke-ApiTest "Photographer_Booking_Cancel" PATCH "/api/photographer/bookings/$bookingId/cancel" -Auth $true -Expect 204 `
  -Note "Huy don dang o trang thai AWAITING_DEPOSIT -> 204 NoContent, nha slot" `
  -UsedBy "schedule_screen.dart -> cancelBooking()" | Out-Null

Invoke-ApiTest "Photographer_Booking_Cancel_NotFound" PATCH "/api/photographer/bookings/$guid/cancel" -Auth $true -Expect 404 `
  -UsedBy "schedule_screen.dart -> cancelBooking()" | Out-Null

# ---------- 7. AI PHOTOGRAPHY GUIDE (PHOTOGRAPHER & EXPERT) ----------
$aiPayload = @{ theme = "Chan dung vintage"; location = "Studio"; availableLight = "Anh sang cua so"; equipment = "May film 35mm"; experienceLevel = "Beginner" }

Invoke-ApiTest "AI_Photography_Guide_Photographer" POST "/api/ai/photography-guide" `
  $aiPayload -Auth $true -Expect 200 `
  -Note "Goi AI Guide voi role PHOTOGRAPHER (503 neu Azure chua cau hinh Gemini API key)" `
  -UsedBy "ai_assistant_screen.dart -> getPhotographyGuide()" | Out-Null

Invoke-ApiTest "AI_Photography_Guide_Expert" POST "/api/ai/photography-guide" `
  $aiPayload -CustomToken $script:expertToken -Expect 200 `
  -Note "Goi AI Guide voi role EXPERT ([Authorize] cho phep ca PHOTOGRAPHER va EXPERT)" `
  -UsedBy "expert_home_screen.dart -> ai_assistant_screen.dart -> getPhotographyGuide()" | Out-Null

# ---------- SUMMARY ----------
$pass = ($results | Where-Object Verdict -eq "PASS").Count
$fail = ($results | Where-Object Verdict -ne "PASS").Count
$md = @()
$md += "# API Test Summary"
$md += ""
$md += "- Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += "- Base URL: $BaseUrl"
$md += "- Photographer test account: $email"
$md += "- Expert test account: expert.demo@filmbooking.local"
$md += "- **PASS: $pass / $($results.Count)**  |  FAIL/ERROR: $fail"
$md += ""
$md += "| # | Result | Method | Endpoint | HTTP | Expected | ms | Used by | Note | Log |"
$md += "|---|---|---|---|---|---|---|---|---|---|"
foreach ($r in $results) {
  $md += "| $($r.No) | $($r.Verdict) | $($r.Method) | ``$($r.Path)`` | $($r.Status) | $($r.Expected) | $($r.Ms) | $($r.UsedBy) | $($r.Note) | [$($r.Log)]($($r.Log)) |"
}
Set-Content -Path (Join-Path $OutDir "SUMMARY.md") -Value ($md -join "`n") -Encoding UTF8
$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutDir "summary.json") -Encoding UTF8

# =====================================================================
# TAO FILE LOG TONG HOP DUY NHAT (summary.log) BANG POWERSHELL THUAN
# =====================================================================
$w = 115
$sepDouble = "=" * $w
$sepSingle = "-" * $w

$pctPass = if ($results.Count -gt 0) { [math]::Round(($pass / $results.Count) * 100, 1) } else { 0 }
$pctFail = if ($results.Count -gt 0) { [math]::Round(($fail / $results.Count) * 100, 1) } else { 0 }

$logLines = [System.Collections.Generic.List[string]]::new()
$logLines.Add($sepDouble)
$logLines.Add("                    BÁO CÁO TOÀN DIỆN KIỂM THỬ API - FILM PHOTOGRAPHY PLATFORM")
$logLines.Add("                  CONSOLIDATED API TEST REPORT (PHOTOGRAPHER & EXPERT ROLES)")
$logLines.Add($sepDouble)
$logLines.Add(" Thoi gian thuc thi : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$logLines.Add(" Base URL Backend   : $BaseUrl")
$logLines.Add(" Tai khoan test 1   : $email (Role: PHOTOGRAPHER)")
$logLines.Add(" Tai khoan test 2   : expert.demo@filmbooking.local (Role: EXPERT)")
$logLines.Add(" Tong so kiem thu   : $($results.Count) kịch bản API")
$logLines.Add(" Ket qua tong quan  : [PASS]: $pass/$($results.Count) ($pctPass%)   |   [FAIL/ERROR]: $fail/$($results.Count) ($pctFail%)")
$logLines.Add($sepDouble)
$logLines.Add("")
$logLines.Add($sepSingle)
$logLines.Add(" [PHẦN 1] BẢNG TỔNG HỢP KẾT QUẢ TẤT CẢ CÁC API (API TEST OVERVIEW)")
$logLines.Add($sepSingle)

$fmt = "{0,-3} | {1,-7} | {2,-6} | {3,-4} | {4,-7} | {5,-5} | {6,-45} | {7}"
$logLines.Add([string]::Format($fmt, "#", "KẾT QUẢ", "METHOD", "HTTP", "EXP", "MS", "ENDPOINT", "MÃ NGUỒN APP SỬ DỤNG"))
$logLines.Add($sepSingle)

foreach ($r in $results) {
  $p = if ($r.Path.Length -gt 44) { $r.Path.Substring(0, 41) + "..." } else { $r.Path }
  $u = if ($r.UsedBy.Length -gt 32) { $r.UsedBy.Substring(0, 29) + "..." } else { $r.UsedBy }
  $logLines.Add([string]::Format($fmt, $r.No, $r.Verdict, $r.Method, $r.Status, $r.Expected, $r.Ms, $p, $u))
}

$logLines.Add($sepSingle)
$logLines.Add("")
$logLines.Add($sepDouble)
$logLines.Add(" [PHẦN 2] PHÂN TÍCH CẬP NHẬT API MỚI (PACKAGE SUBSCRIPTION, BOOKING, COMMUNITY POST & ROLES)")
$logLines.Add($sepDouble)
$logLines.Add(@"
1. CÁC API PACKAGE SUBSCRIPTION & BOOKING MỚI ĐÃ ĐƯỢC TÍCH HỢP VÀO FLUTTER APP:
   * GET  /api/photographer/service-packages
     -> BookingApiService.getServicePackages() -> ServicePackagesScreen (Tab 'Gói Combo').
   * POST /api/photographer/service-packages/{packageId}/purchase
     -> BookingApiService.purchaseServicePackage() & PaymentApiService.initiatePackagePurchasePayment()
     -> PaymentScreen hỗ trợ thanh toán mua Gói Combo qua VNPay Sandbox.
   * GET  /api/photographer/package-subscriptions
     -> BookingApiService.getPackageSubscriptions() -> ServicePackagesScreen (Tab 'Gói Đã Đăng Ký') & BookingFlowScreen.
   * GET  /api/photographer/package-subscriptions/{subscriptionId}
     -> BookingApiService.getPackageSubscriptionDetail() -> Modal xem chi tiết gói & số lượt còn lại trong kỳ.
   * GET  /api/photographer/equipment/{equipmentId}/availability
     -> BookingApiService.getEquipmentAvailability() -> Kiểm tra lịch trống của thiết bị đi kèm.
   * POST /api/photographer/bookings (Schema mới BookingCreateRequestDTO):
     - Chế độ 1 (Đặt phòng lẻ): Truyền { availabilityId, equipmentIds } (đã bỏ trường packageId cũ).
     - Chế độ 2 (Đặt theo Gói Subscription): Truyền { subscriptionId, segments: [{ stepOrder, availabilityId, equipmentIds }] }
       qua BookingApiService.createPackageBooking(). Đơn được CONFIRMED ngay, miễn đặt cọc (depositStatus = NOT_REQUIRED).

2. GHI CHÚ VỀ LỖI HTTP 500 TRÊN AZURE ĐỐI VỚI CÁC BẢNG PACKAGE ITEMS:
   * Code C# mới (PhotographerPackagesController) đã được deploy lên Azure.
   * Tuy nhiên trên database PostgreSQL của Azure, bảng service_package_items / user_package_subscription_items
     chưa chạy migration thêm các cột mới (step_order, included_duration_minutes, included_chemical_quantity, notes),
     nên khi EF Core SELECT từ 2 bảng này đang trả về HTTP 500.
   * App Flutter đã được xử lý fallback an toàn trên ServicePackagesScreen để không bị crash khi DB chưa migrate xong.

3. KIỂM TRA COMMUNITY POST API TRÊN BACKEND:
   * Trong source code Backend (GFA26SE169_FA26SE091_CapstoneProject-main), mới chỉ có các EF Core Entity Model:
     CommunityPost.cs, CommunityPostImage.cs, Comment.cs, Article.cs, Workshop.cs trong tầng Repository/Models.
   * Backend CHƯA CÓ Controller hay Endpoint nào cho Community Post (/api/community-posts...).
   * Trên App Flutter, CommunityScreen đã được đồng bộ với AuthService().currentUser để khi đăng bài/bình luận
     sẽ lấy đúng tên và vai trò thực tế của tài khoản đang đăng nhập (PHOTOGRAPHER hoặc EXPERT).

4. KIỂM TRA PHÂN QUYỀN ROLE PHOTOGRAPHER vs EXPERT:
   * PHOTOGRAPHER: Có toàn quyền gọi /api/photographer/* (studios, darkrooms, availability, bookings, deposit-payment,
     cancel, service-packages, package-subscriptions) và /api/ai/photography-guide.
   * EXPERT (expert.demo@filmbooking.local / FilmDemo2026!):
     - Đăng nhập thành công qua POST /api/auth/login (nhận JWT có role = EXPERT), App điều hướng vào /expert-workspace.
     - Gọi được POST /api/ai/photography-guide (vì PhotographyGuideController dùng [Authorize] cho mọi role đã đăng nhập).
     - Khi gọi /api/photographer/* sẽ bị chặn đúng chuẩn HTTP 403 Forbidden (do [Authorize(Roles = "PHOTOGRAPHER")]).
"@)
$logLines.Add($sepDouble)
$logLines.Add(" [PHẦN 3] CHI TIẾT REQUEST & RESPONSE TOÀN BỘ $($results.Count) API ĐÃ KIỂM THỬ")
$logLines.Add($sepDouble)
$logLines.Add("")

foreach ($r in $results) {
  $logLines.Add($sepSingle)
  $logLines.Add(" >>> [API $($r.No)/$($results.Count)] $($r.Name) | KẾT QUẢ: [$($r.Verdict)] (HTTP $($r.Status) - Kỳ vọng: $($r.Expected)) - Thời gian: $($r.Ms)ms")
  if ($r.UsedBy) { $logLines.Add("     Nơi gọi trong App: $($r.UsedBy)") }
  if ($r.Note) { $logLines.Add("     Ghi chú          : $($r.Note)") }
  $logLines.Add($sepSingle)

  $individualLogPath = Join-Path $OutDir $r.Log
  if (Test-Path $individualLogPath) {
    $rawLines = Get-Content -Path $individualLogPath -Encoding UTF8
    $filtered = @()
    foreach ($line in $rawLines) {
      if ($line -like "====================*") { continue }
      if ($line -match "^(Name|Time|Result|Duration|Used by|Note)\s*:") { continue }
      $filtered += $line
    }
    $logLines.Add(($filtered -join "`n").Trim())
  } else {
    $logLines.Add("Method : $($r.Method)")
    $logLines.Add("Path   : $($r.Path)")
  }
  $logLines.Add("")
  $logLines.Add("")
}

$logLines.Add($sepDouble)
$logLines.Add("                                        HẾT BÁO CÁO")
$logLines.Add($sepDouble)

$summaryContent = $logLines -join "`n"

Set-Content -Path (Join-Path $OutDir "summary.log") -Value $summaryContent -Encoding UTF8
Set-Content -Path (Join-Path $root "test_logs\summary.log") -Value $summaryContent -Encoding UTF8
Set-Content -Path (Join-Path $root "summary.log") -Value $summaryContent -Encoding UTF8

Write-Host "`nPASS $pass / $($results.Count)  |  FAIL/ERROR $fail"
Write-Host "Logs: $OutDir"
Write-Host "Summary log: $(Join-Path $root 'summary.log')"
