# Sayfa Paylaş (TEST SÜRÜMÜ 0.2)

Sayfa sayfa **metin** paylaşma ve okuma uygulaması. Akış, beğeni, yorum ve kaydetme var.
Paylaşılan her sayfa **senin onayından** geçmeden herkese görünmez.

## Parçalar (basit anlatım)
- **Sunucu** (`server/server.py`): Sayfaların, beğenilerin ve yorumların durduğu küçük program.
- **Uygulama** (`lib/main.dart`): Telefona kurulan APK. Aynı uygulama hem kullanıcı hem yönetici.
- **Derleme** (`.github/workflows/build.yml`): GitHub'a yüklediğinde APK'yı senin yerine üretir.

## Kullanıcı tarafı
- İlk açılışta **isim** istenir (zorunlu). Hakkında ve iletişim **isteğe bağlı**. Şifre/e-posta yok.
- **Akış:** Yeni sayfalar alt alta. Beğen, yorum say, kaydet. Üstte arama, kategori ve "sadece kaydedilenler".
- **Okuma:** Beyaz zemin, siyah yazı. Sağ üstteki **Aa** düğmesi: yazı boyutu, satır aralığı, serif/düz yazı tipi. Ayarlar hatırlanır.
- **Paylaş:** Başlık + kategori + metin yaz → gönder. Onay bekler.
- **Profil:** İsim, sunucu adresi, dil, yönetici anahtarı.

## Yönetici tarafı
Profil'e yönetici anahtarını (ADMIN_KEY) yaz → Kaydet → **Yönetici** sekmesi açılır. Üç bölüm:
1. **Sayfalar:** Bekleyenleri işaretle → onayla / hepsini onayla / sil / cihazı engelle.
2. **Yorumlar:** Aynı işlemler yorumlar için.
3. **Ayar:** Yorumlar *otomatik yayınlansın* ya da *benim onayımı beklesin*. İstediğin an değiştirebilirsin.

## 1) Sunucuyu çalıştır
```
pip install flask
ADMIN_KEY=benim-gizli-anahtarim python server/server.py
```
(Windows: `set ADMIN_KEY=benim-gizli-anahtarim` yaz, sonra `python server/server.py`.)
- Adres: `http://BILGISAYAR_IP:5000`
- Veriler `data` klasöründe. Yedek için o klasörü kopyala.
- Eski 0.1 sürümünden geliyorsan sorun yok; yeni sürüm ayrı dosya kullanır.

## 2) APK üret
1. GitHub deposundaki dosyaları bu klasörle değiştir (`.github` dahil).
2. **Actions → apk → Run workflow.** Bitince **Artifacts** kısmından APK'yı indir (armeabi-v7a ve arm64 ayrı gelir).

## Sunucu adresini değiştirmek
Profil → Sunucu adresi → yeni adres → Kaydet. APK yeniden üretmek gerekmez.

## Gizlilik
- IP adresi saklanmaz. Uygulama rastgele bir cihaz numarası üretir; engelleme bununla yapılır.
- Uygulama silinip kurulursa numara değişir, bu yüzden engel %100 değildir.
- Sunucuda saklananlar: isim, (varsa) hakkında/iletişim, sayfalar, yorumlar, beğeniler.

## Henüz yok
Profil fotoğrafı, yönetici uygulamasında sayfa düzenleme ekranı (sunucu tarafı hazır), yorum silme/engel kaldırma listesi,
40 MB paketler ve kullanıcılar arası dağıtım, PDF araçları, HTTPS.

## Uyarı
Test sürümü şifresiz `http` kullanır. Gerçek kullanıcılara açmadan önce HTTPS'e geçilmeli.
