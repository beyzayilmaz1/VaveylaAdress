# Vaveyla

Flutter müşteri / restoran uygulaması ve .NET 8 backend API.

## Hızlı başlangıç

### Backend

```powershell
cd backend\Vaveyla.Api
dotnet run
```

API: `http://localhost:5142`

### Flutter

```powershell
flutter pub get
flutter run
```

Test hesapları: `TEST_VERILERI.md` — `@vaveyla.com` adresleri gerçek posta kutusu değildir.

## Şifre sıfırlama / Gmail SMTP

Ayrıntılı kurulum: **[backend/Vaveyla.Api/README.md](backend/Vaveyla.Api/README.md)**

1. Google 2 adımlı doğrulama + uygulama şifresi
2. `dotnet user-secrets` ile `Email:Username`, `Email:Password`, `Email:FromAddress`
3. `dotnet run` → startup loglarında SMTP `DOLU` olmalı
4. **Gerçek Gmail** ile test; Spam klasörünü kontrol edin

SMTP başarısızsa kullanıcıya hata gösterilir; sahte başarı yoktur.
"# VaveylaAdress" 
"# VaveylaAdress" 
"# VaveylaYorum" 
