# API Test Summary

- Time: 2026-11-21 08:34:05
- Base URL: https://filmbooking-api-h7bghwcydwb8eecn.japaneast-01.azurewebsites.net
- Test account: apitest_20261121_083355@example.com
- **PASS: 15 / 25**  |  FAIL/ERROR: 10

| # | Result | Method | Endpoint | HTTP | Expected | ms | Used by | Note | Log |
|---|---|---|---|---|---|---|---|---|---|
| 01 | PASS | POST | `/api/auth/register/photographer` | 201 | 201 | 1212 | auth_service.dart register() |  | [01_Auth_Register_Photographer.log](01_Auth_Register_Photographer.log) |
| 02 | PASS | POST | `/api/auth/register/photographer` | 409 | 409 | 787 | auth_service.dart register() | App xu ly 409 = email da ton tai | [02_Auth_Register_Duplicate_Email.log](02_Auth_Register_Duplicate_Email.log) |
| 03 | PASS | POST | `/api/auth/login` | 200 | 200 | 752 | auth_service.dart login() |  | [03_Auth_Login_OK.log](03_Auth_Login_OK.log) |
| 04 | PASS | POST | `/api/auth/login` | 401 | 401 | 1132 | auth_service.dart login() |  | [04_Auth_Login_WrongPassword.log](04_Auth_Login_WrongPassword.log) |
| 05 | PASS | GET | `/api/photographer/studios` | 401 | 401 | 114 |  | Khong co token phai bi chan | [05_Photographer_Studios_NoToken.log](05_Photographer_Studios_NoToken.log) |
| 06 | PASS | GET | `/api/photographer/studios` | 200 | 200 | 170 | home_screen.dart, item_list_screen.dart -> getStudios() |  | [06_Photographer_Studios.log](06_Photographer_Studios.log) |
| 07 | PASS | GET | `/api/photographer/darkrooms` | 200 | 200 | 167 | home_screen.dart, item_list_screen.dart -> getDarkrooms() |  | [07_Photographer_Darkrooms.log](07_Photographer_Darkrooms.log) |
| 08 | PASS | GET | `/api/photographer/studios?fromDate=2026-11-21&toDate=2026-12-21` | 200 | 200 | 359 | item_list_screen.dart (loc theo ngay) |  | [08_Photographer_Studios_DateFilter.log](08_Photographer_Studios_DateFilter.log) |
| 09 | FAIL | GET | `/api/photographer/spaces/21355b64-d365-405c-931a-b46e59c552b9/availability?fromDate=2026-11-21&toDate=2026-12-21` | 404 | 200 | 324 | booking_api_service.dart getAvailableSlots() | Response dung key availableDate (model Flutter dang doc 'date') | [09_Photographer_Space_Availability.log](09_Photographer_Space_Availability.log) |
| 10 | PASS | GET | `/api/photographer/bookings?page=1&pageSize=20` | 200 | 200 | 213 | getMyBookings() - chua noi vao UI | Response dung totalItems (model Flutter dang doc 'totalCount') | [10_Photographer_Bookings_List.log](10_Photographer_Bookings_List.log) |
| 11 | FAIL | POST | `/api/photographer/bookings` | 409 | 201 | 362 | booking_flow_screen.dart _submitBooking() |  | [11_Photographer_Booking_Create.log](11_Photographer_Booking_Create.log) |
| 12 | PASS | POST | `/api/photographer/bookings` | 409 | 409 | 302 |  | Slot khong ton tai | [12_Photographer_Booking_Create_BadSlot.log](12_Photographer_Booking_Create_BadSlot.log) |
| 13 | FAIL | GET | `/api/photographer/bookings/21355b64-d365-405c-931a-b46e59c552b9` | 404 | 200 | 990 | getBookingDetail() - chua noi vao UI |  | [13_Photographer_Booking_Detail.log](13_Photographer_Booking_Detail.log) |
| 14 | FAIL | POST | `/api/photographer/bookings/21355b64-d365-405c-931a-b46e59c552b9/deposit-payment` | 404 | 200 | 306 | booking_api_service.dart payDeposit() (khong duoc UI goi) | API thanh toan CHUAN. Tra paymentUrl VNPay sandbox. App chua goi payDeposit() | [14_Payment_DepositPayment_VNPAY.log](14_Payment_DepositPayment_VNPAY.log) |
| 15 | PASS | POST | `/api/photographer/bookings/21355b64-d365-405c-931a-b46e59c552b9/deposit-payment` | 400 | 400 | 268 |  | BE chi ho tro VNPAY (UI van hien MoMo) | [15_Payment_DepositPayment_MOMO.log](15_Payment_DepositPayment_MOMO.log) |
| 16 | PASS | POST | `/api/photographer/bookings/21355b64-d365-405c-931a-b46e59c552b9/deposit-payment` | 400 | 400 | 331 |  | BE chi ho tro VNPAY (UI van hien VietQR) | [16_Payment_DepositPayment_VIETQR.log](16_Payment_DepositPayment_VIETQR.log) |
| 17 | PASS | POST | `/api/photographer/bookings/BK-123456/deposit-payment` | 404 | 404 | 248 |  | App tao ma gia BK-xxxx khi dat phong loi -> thanh toan se 404 | [17_Payment_DepositPayment_FakeBookingId.log](17_Payment_DepositPayment_FakeBookingId.log) |
| 18 | FAIL | POST | `/api/payments/vnpay/create` | 404 | 200/201 | 345 | payment_api_service.dart createPaymentUrl() | Endpoint KHONG ton tai tren BE (404) nhung app dang goi | [18_Payment_Create_VNPAY_AppCalls.log](18_Payment_Create_VNPAY_AppCalls.log) |
| 19 | FAIL | POST | `/api/payments/momo/create` | 404 | 200/201 | 308 | payment_api_service.dart createPaymentUrl() | Endpoint KHONG ton tai tren BE | [19_Payment_Create_MOMO_AppCalls.log](19_Payment_Create_MOMO_AppCalls.log) |
| 20 | FAIL | GET | `/api/payments/vnpay/return?vnp_Amount=15000000&vnp_BankCode=NCB&vnp_OrderInfo=Test&vnp_ResponseCode=00&vnp_TransactionNo=123456&vnp_TxnRef=21355b64-d365-405c-931a-b46e59c552b9` | 400 | 200 | 118 | payment_api_service.dart verifyVnpayReturn() | App gui tham so gia khong co vnp_SecureHash -> BE tu choi (400) | [20_Payment_VNPay_Return_AppFakeParams.log](20_Payment_VNPay_Return_AppFakeParams.log) |
| 21 | FAIL | GET | `/api/payments/momo/return?PartnerCode=MOMO&OrderId=21355b64-d365-405c-931a-b46e59c552b9&ResultCode=0&Signature=dummy_momo_signature` | 404 | 200 | 134 | payment_api_service.dart verifyMomoReturn() | Route MoMo da bi go khoi BE | [21_Payment_MoMo_Return_AppFakeParams.log](21_Payment_MoMo_Return_AppFakeParams.log) |
| 22 | PASS | GET | `/api/payments/vnpay/ipn?vnp_TxnRef=abc&vnp_ResponseCode=00&vnp_SecureHash=bad` | 200 | 200 | 120 |  | Server-to-server cua VNPay, app khong goi. RspCode 99 la binh thuong | [22_Payment_VNPay_IPN.log](22_Payment_VNPay_IPN.log) |
| 23 | FAIL | PATCH | `/api/photographer/bookings/21355b64-d365-405c-931a-b46e59c552b9/cancel` | 404 | 204 | 228 | cancelBooking() - chua noi vao UI |  | [23_Photographer_Booking_Cancel.log](23_Photographer_Booking_Cancel.log) |
| 24 | PASS | PATCH | `/api/photographer/bookings/21355b64-d365-405c-931a-b46e59c552b9/cancel` | 404 | 404 | 146 |  |  | [24_Photographer_Booking_Cancel_NotFound.log](24_Photographer_Booking_Cancel_NotFound.log) |
| 25 | FAIL | POST | `/api/ai/photography-guide` | 503 | 200 | 256 | ai_assistant_screen.dart, home_screen.dart -> getPhotographyGuide() |  | [25_AI_Photography_Guide.log](25_AI_Photography_Guide.log) |
