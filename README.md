# SafeZone Mobile

Ứng dụng Flutter đa nền tảng dành cho người dân và cộng đồng theo dõi tình hình dịch bệnh, xem bản đồ vùng dịch, đọc thông tin y tế, gửi báo cáo và nhận thông báo.

## Chức năng chính

- Đăng ký, đăng nhập, xác minh tài khoản và quản lý hồ sơ
- Dashboard thống kê tình hình dịch bệnh
- Bản đồ vùng dịch và tìm kiếm khu vực
- Báo cáo ca bệnh
- Thông tin y tế và bài viết cộng đồng
- Bình luận, tương tác và lưu nội dung
- Thông báo đẩy qua Firebase Cloud Messaging
- Lưu cache và bản nháp cục bộ bằng Hive
- Chia sẻ nội dung và mở liên kết ngoài

## Công nghệ

- Flutter và Dart
- Provider cho state management
- Dio cho HTTP client
- Hive và Shared Preferences cho lưu trữ local
- Flutter Map và Geolocator cho bản đồ/vị trí
- Firebase Core, Firebase Messaging và local notifications

## Yêu cầu

- Flutter SDK tương thích Dart `^3.9.2`
- Android Studio/Xcode tùy nền tảng
- Firebase project nếu cần push notification
- SafeZone API đang chạy hoặc đã triển khai

Kiểm tra môi trường:

```powershell
flutter doctor
```

## Cài đặt

```powershell
cd apps/mobile_flutter
flutter pub get
```

Firebase native configuration cần được thiết lập cho nền tảng tương ứng. Không commit credential hoặc file cấu hình riêng chứa secret.

## Cấu hình API

Ứng dụng mặc định sử dụng API production được khai báo trong `lib/core/constants/api_constants.dart`.

Để chạy với API local, truyền host qua `--dart-define`:

```powershell
# Android Emulator
flutter run --dart-define=API_HOST=10.0.2.2 --dart-define=API_PORT=3002

# Thiết bị thật trong cùng mạng LAN
flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=3002
```

Theo cấu hình hiện tại, ứng dụng tạo base URL dạng:

```text
http://<API_HOST>:<API_PORT>/api/v1
```

Thiết bị thật không thể dùng `localhost` để truy cập API chạy trên máy phát triển.

## Chạy và build

```powershell
# Chạy ứng dụng
flutter run

# Liệt kê thiết bị
flutter devices

# Build Android APK
flutter build apk --release

# Build web
flutter build web --release
```

Build iOS cần macOS và Xcode:

```powershell
flutter build ios --release
```

## Kiểm tra mã nguồn

```powershell
flutter analyze
flutter test
```

## Tạo code Hive

Khi thay đổi model có generated adapter:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Cấu trúc thư mục

```text
lib/
  core/           # Constants, network, theme và tiện ích
  data/           # Models, repositories và data sources
  domain/         # Entity và business logic
  presentation/   # Screens, widgets và state providers
  app.dart        # Root MaterialApp
  main.dart       # Khởi tạo Firebase, Hive và ứng dụng
test/             # Unit/widget tests
```

Kiến trúc chi tiết xem [FLUTTER_ARCHITECTURE.md](../../docs/FLUTTER_ARCHITECTURE.md).

## Kết nối backend

API dùng JWT trong header `Authorization`. Các endpoint và request mẫu được mô tả trong [MOBILE_API_DOCUMENTATION.md](../../docs/MOBILE_API_DOCUMENTATION.md).

Khi backend chạy local, cần bảo đảm:

1. API đang lắng nghe trên địa chỉ mà thiết bị truy cập được.
2. Cổng API khớp với `API_PORT`.
3. Database và dữ liệu seed đã sẵn sàng.
4. Firebase được cấu hình nếu kiểm thử thông báo đẩy.

## Lưu ý phát hành

- Cập nhật version/build number trong `pubspec.yaml` trước khi phát hành.
- Thiết lập signing Android/iOS theo tài liệu nền tảng.
- Dùng endpoint production khi build release.
- Không đưa private key, token hoặc credential Firebase vào repository.

