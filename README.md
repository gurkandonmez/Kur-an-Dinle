Özellikler

Sûre listesi: İlk 10’u yükleme + Devamını getir (sayfalama)

Akıllı arama: Aksan/şapka/ı-i normalizasyonu (diacritic)

Detay ekranı: Ayet listesi, tek tek çalma veya “Tümünü Çal”

Durum etiketi: Mekkî / Medenî ve “X ayet” kutucukları

api (ASP.NET Core 8) ──> SQL Server (EF Core) ──> wwwroot/audio/*.mp3
          ↑
          └──────── Flutter (Android) — http: 10.0.2.2:{port}
Backend: ASP.NET Core Web API (.NET 8), EF Core, SQL Server

Frontend: Flutter (http, just_audio, scrollable_positioned_list, diacritic)

-----------------

Kur-an-Dinle

Flutter + .NET 8 based Qur’an Audio application.
Browse surahs, search quickly, and play ayahs individually or sequentially. Search is accent-insensitive (e.g., “Yâsîn / Yasin”).

✨ Features

Surah list: First 10 items + Load More pagination

Smart search: Accent/case normalization (diacritic handling)

Detail screen: Ayah list, single play or Play All queue

Status tags: Makkī / Madanī and “X ayahs” as chips

MP3 streaming: Served by .NET API from wwwroot/audio/...

Splash & store art: Auto-generated icon/feature graphic

Architecture
/api (ASP.NET Core 8) ──> SQL Server (EF Core) ──> wwwroot/audio/*.mp3
          ↑
          └──────── Flutter (Android) — http: 10.0.2.2:{port}


Backend: ASP.NET Core Web API (.NET 8), EF Core, SQL Server

Frontend: Flutter (http, just_audio, scrollable_positioned_list, diacritic)
