# Kur-an-Dinle / Quran Audio App

Flutter + .NET 8 tabanlı **Sesli Kur’an** uygulaması.  
Flutter + .NET 8 based **Qur’an Audio** application.

---

## 🇹🇷 Türkçe

### ✨ Özellikler
- **Sûre listesi**: İlk 10, “Devamını getir” ile sayfalama
- **Akıllı arama**: Aksan/şapka/ı-i normalizasyonu (diacritic)
- **Detay**: Âyet listesi, tek tek çalma veya **Tümünü Çal**
- **Durum etiketleri**: **Mekkî/Medenî** ve **“X ayet”** kutuları
- **MP3 yayın**: .NET API → `wwwroot/audio/...`
- **Splash & vitrin**: Üretilmiş ikon/feature graphic

### 🏗 Mimari
```
/api (ASP.NET Core 8) ──> SQL Server (EF Core) ──> wwwroot/audio/*.mp3
          ↑
          └──────── Flutter (Android) — http: 10.0.2.2:{port}
```

### 🔌 API Uç Noktaları
| Yöntem | URL               | Açıklama                          |
|------: |-------------------|-----------------------------------|
| GET    | `/api/surah`      | Tüm sûrelere ait özet             |
| GET    | `/api/surah/{id}` | Sûre + âyetler (MP3 yolları, süre)|

> API relatif yolları tam URL’ye çevirir (örn. `http://localhost:5035/audio/...`).

### ⚙️ Backend Kurulum (ASP.NET Core 8)
1. **NuGet**
   ```powershell
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add package Microsoft.EntityFrameworkCore.Tools
   dotnet add package Swashbuckle.AspNetCore
   dotnet add package TagLibSharp
   ```
2. **EF Core / Migration**
   ```powershell
   dotnet ef migrations add Init
   dotnet ef database update
   ```
3. **Ses dosyaları**
   ```text
   QuranApi/wwwroot/audio/
     ├─ 001 - Fâtiha/001.mp3 ... 007.mp3
     ├─ 002 - Bakara/001.mp3 ... 286.mp3
     └─ ...
   ```
4. **Geliştirme URL’si**
   `Properties/launchSettings.json`’daki HTTP portu not alın (örn. `http://localhost:5035`).  
   Android emülatörü PC’nizdeki `localhost`’a **`10.0.2.2`** ile erişir.

### 📱 Flutter Kurulum
1. **pubspec.yaml**
   ```yaml
   dependencies:
     http: ^1.2.0
     just_audio: ^0.9.38
     scrollable_positioned_list: ^0.3.8
     diacritic: ^0.1.3

   dev_dependencies:
     flutter_native_splash: ^2.4.4
   ```
2. **API tabanı**
   ```dart
   // Emülatörde: localhost => 10.0.2.2
   const String kBase = 'http://10.0.2.2:5035';
   // veya --dart-define ile:
   const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:5035');
   ```
3. **Android cleartext (HTTP)**
   `AndroidManifest.xml`:
   ```xml
   <application
     android:usesCleartextTraffic="true"
     android:networkSecurityConfig="@xml/network_security_config" ...>
   </application>
   ```
   `android/app/src/main/res/xml/network_security_config.xml`:
   ```xml
   <network-security-config>
     <domain-config cleartextTrafficPermitted="true">
       <domain includeSubdomains="true">10.0.2.2</domain>
     </domain-config>
   </network-security-config>
   ```
4. **Splash** (`flutter_native_splash`)
   ```yaml
   flutter_native_splash:
     color: "#36D1DC"
     image: assets/images/splash_icon.png
     android_12:
       color: "#36D1DC"
       image: assets/images/splash_icon.png
   ```
   ```bash
   flutter pub get
   flutter pub run flutter_native_splash:create
   ```
5. **Çalıştır**
   ```bash
   flutter run
   ```

### 🧠 Arama Normalizasyonu
- `diacritic` + özel dönüşümler ile “Yâsîn / Yasin / yasin” hepsi eşleşir.  
- Sunucu tarafında aksan/büyük-küçük harf duyarsız collation kullanılabilir (örn. `Turkish_100_CI_AI`).

### 🖼 Ekran Görüntüleri (Öneri)
`/docs/screenshots/` klasörüne:
- Hoş geldiniz
- Sûre listesi (arama açık)
- Detay (Tümünü Çal)
- Çalan âyet vurgusu

### 📦 İçerik / Telif
- MP3/tilavet ve metin kaynaklarının lisansına/iznine uyun. Gerekirse **atıf** ekleyin.

### 🛣 Yol Haritası
- [ ] Offline indirme/önbellek
- [ ] Favoriler & kaldığı yerden devam
- [ ] Meâl & Arapça metin
- [ ] HTTPS + yapılandırılabilir `API_BASE`
- [ ] Widget/Foreground service

### 📜 Lisans
Bu repo için bir lisans seçin (ör. MIT/Apache-2.0).  
Ses içerikleri ayrı lisans/atıf gerektirebilir.

---

## 🇬🇧 English

### ✨ Features
- **Surah list**: First 10 + “Load More” pagination
- **Smart search**: Accent/case normalization
- **Detail**: Ayah list, single play or **Play All**
- **Status chips**: **Makkī/Madanī** and **“X ayahs”** boxes
- **MP3 streaming**: .NET API → `wwwroot/audio/...`
- **Splash & store art**: Generated icon/feature graphic

### 🏗 Architecture
```
/api (ASP.NET Core 8) ──> SQL Server (EF Core) ──> wwwroot/audio/*.mp3
          ↑
          └──────── Flutter (Android) — http: 10.0.2.2:{port}
```

### 🔌 API Endpoints
| Method | URL               | Description                         |
|------: |-------------------|-------------------------------------|
| GET    | `/api/surah`      | All surahs (summary list)           |
| GET    | `/api/surah/{id}` | Surah + ayahs (MP3 paths, duration) |

> API converts relative paths to absolute URLs (e.g., `http://localhost:5035/audio/...`).

### ⚙️ Backend Setup (ASP.NET Core 8)
1. **NuGet**
   ```powershell
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add package Microsoft.EntityFrameworkCore.Tools
   dotnet add package Swashbuckle.AspNetCore
   dotnet add package TagLibSharp
   ```
2. **EF Core / Migrations**
   ```powershell
   dotnet ef migrations add Init
   dotnet ef database update
   ```
3. **Audio files**
   ```text
   QuranApi/wwwroot/audio/
     ├─ 001 - Fâtiha/001.mp3 ... 007.mp3
     ├─ 002 - Bakara/001.mp3 ... 286.mp3
     └─ ...
   ```
4. **Dev URL**
   Find the HTTP port in `Properties/launchSettings.json` (e.g., `http://localhost:5035`).  
   Android emulator reaches your PC’s localhost via **`10.0.2.2`**.

### 📱 Flutter Setup
1. **pubspec.yaml**
   ```yaml
   dependencies:
     http: ^1.2.0
     just_audio: ^0.9.38
     scrollable_positioned_list: ^0.3.8
     diacritic: ^0.1.3

   dev_dependencies:
     flutter_native_splash: ^2.4.4
   ```
2. **API base**
   ```dart
   const String kBase = 'http://10.0.2.2:5035';
   // Or via --dart-define
   const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:5035');
   ```
3. **Allow cleartext HTTP (Android)**
   `AndroidManifest.xml`:
   ```xml
   <application
     android:usesCleartextTraffic="true"
     android:networkSecurityConfig="@xml/network_security_config" ...>
   </application>
   ```
   `android/app/src/main/res/xml/network_security_config.xml`:
   ```xml
   <network-security-config>
     <domain-config cleartextTrafficPermitted="true">
       <domain includeSubdomains="true">10.0.2.2</domain>
     </domain-config>
   </network-security-config>
   ```
4. **Splash** (`flutter_native_splash`)
   ```yaml
   flutter_native_splash:
     color: "#36D1DC"
     image: assets/images/splash_icon.png
     android_12:
       color: "#36D1DC"
       image: assets/images/splash_icon.png
   ```
   ```bash
   flutter pub get
   flutter pub run flutter_native_splash:create
   ```
5. **Run**
   ```bash
   flutter run
   ```

### 🧠 Search Normalization
- With `diacritic` + custom replacements, “Yâsîn / Yasin / yasin” all match.  
- Optionally implement server-side accent/case-insensitive search (e.g., `Turkish_100_CI_AI` collation).

### 🖼 Screenshots (Suggested)
Put into `/docs/screenshots/`:
- Welcome
- Surah list (with search)
- Detail (Play All)
- Playing ayah highlight

### 📦 Content / Rights
- Ensure audio/text sources are properly **licensed** and allowed for distribution. Add **attribution** if required.

### 🛣 Roadmap
- [ ] Offline download/cache
- [ ] Favorites & resume playback
- [ ] Translation (meāl) & Arabic text
- [ ] HTTPS + configurable `API_BASE`
- [ ] Widget/Foreground service

### 📜 License
Pick a license for this repository (e.g., MIT/Apache-2.0).  
Audio contents may require **separate licensing/attribution**.
