# Rotam Belli

**Rotam Belli**, kargo dağıtımı yapan kuryelerin teslimat adreslerini daha düzenli ve verimli bir sıraya koymasına yardımcı olmak amacıyla geliştirilen Flutter tabanlı bir mobil uygulamadır.

Uygulamanın temel amacı, bir kuryenin gün içinde teslim etmesi gereken çok sayıda kargoyu tek tek düşünerek sıralamak yerine, adresleri sisteme aktararak mümkün olduğunca mantıklı bir teslimat rotası oluşturmaktır.

> Proje şu anda geliştirme aşamasındadır.

## 🎯 Projenin Amacı

Bir kurye gün içerisinde yaklaşık **20–50 farklı adrese** teslimat yapmak zorunda kalabilir.

Adreslerin gelişigüzel sırayla ziyaret edilmesi:

* Gereksiz mesafe kat edilmesine
* Yakıt tüketiminin artmasına
* Teslimat süresinin uzamasına
* Aynı bölgelerde tekrar tekrar dolaşılmasına

neden olabilir.

Rotam Belli, teslimat noktalarını analiz ederek kurye için daha uygun bir ziyaret sırası oluşturmayı hedefler.

## 📍 İlk Pilot Bölge

Projenin ilk prototipi:

**İstanbul / Beylikdüzü / Adnan Kahveci Mahallesi**

üzerinde geliştirilecektir.

İlk aşamada küçük bir bölgede sistemin doğru çalışması sağlandıktan sonra daha geniş bölgelere açılması planlanmaktadır.

## 🚚 Planlanan Özellikler

* Kargo ve teslimat adreslerinin uygulamaya eklenmesi
* Günlük kargoların liste halinde görüntülenmesi
* 20–50 teslimat noktasının sıralanması
* Teslimatlar için optimize edilmiş rota oluşturulması
* Tek yönlü yolların dikkate alınması
* Dönüş yasaklarının dikkate alınması
* U dönüşü yasaklarının dikkate alınması
* Yol kurallarına uygun rota oluşturulması
* Teslim edilen kargoların işaretlenmesi
* Teslim edilen adreslerin aktif rotadan kaldırılması
* Kalan teslimatlara göre rotanın güncellenmesi
* Harita üzerinde teslimat noktalarının gösterilmesi

## 📦 Daha Sonra Eklenmesi Planlanan Özellikler

İlerleyen sürümlerde:

* Excel dosyasından adres aktarma
* CSV dosyasından adres aktarma
* Adresleri otomatik koordinata çevirme
* Gerçek harita entegrasyonu
* Rota optimizasyon motoru
* Kurye konumunun haritada gösterilmesi
* Teslimat geçmişi
* Günlük teslimat istatistikleri
* Birden fazla kurye desteği
* Kargo firmasına özel sistemler

eklenmesi planlanmaktadır.

## 🗺️ Rota Optimizasyonu

Projenin ileri aşamalarında rota hesaplanırken yalnızca iki nokta arasındaki kuş uçuşu mesafe değil, gerçek yol ağı dikkate alınacaktır.

Örneğin:

```text
Kurye
  ↓
Kargo 1
  ↓
Kargo 2
  ↓
Kargo 3
  ↓
...
  ↓
Kargo 30
```

Sistem mümkün olduğunca kısa ve uygulanabilir bir teslimat sırası oluşturacaktır.

İlk prototipte:

* Anlık trafik
* Teslimat saat aralıkları
* Trafik yoğunluğu tahmini

gibi özellikler öncelikli değildir.

Öncelik **yol kurallarına uygun ve mantıklı bir teslimat sırası** oluşturmaktır.

## 🛠️ Kullanılan Teknolojiler

### Mobil uygulama

* **Flutter**
* **Dart**

### Geliştirme ortamı

* Visual Studio Code
* Android Studio
* Android Emulator
* Git

### İleride kullanılabilecek servisler

* Harita API'si
* Geocoding servisi
* Rota motoru
* Optimizasyon algoritmaları

## 📱 Hedef Platform

Projenin ilk sürümü:

**Android**

için geliştirilmektedir.

İlerleyen dönemlerde Flutter'ın çoklu platform desteği kullanılarak diğer platformlara destek eklenebilir.

## 📂 Proje Yapısı

```text
rotam_belli/
│
├── android/
│
├── lib/
│   └── main.dart
│
├── test/
│
├── pubspec.yaml
└── README.md
```

Uygulamanın ana geliştirme dosyaları `lib/` klasörü içerisinde bulunacaktır.

## 🚀 Projeyi Çalıştırma

Flutter'ın bilgisayarınızda kurulu olduğundan emin olun.

Bağımlılıkları yüklemek için:

```bash
flutter pub get
```

Bağlı cihazları görmek için:

```bash
flutter devices
```

Uygulamayı çalıştırmak için:

```bash
flutter run
```

Flutter kurulumunu kontrol etmek için:

```bash
flutter doctor
```

## 🧭 Geliştirme Yol Haritası

### Aşama 1 — Temel uygulama

* [ ] Ana ekran
* [ ] Kargo modeli
* [ ] Kargo ekleme
* [ ] Kargo listesi
* [ ] Teslim edildi butonu
* [ ] Teslim edilen kargonun listeden kaldırılması

### Aşama 2 — Adres sistemi

* [ ] Adres bilgilerinin kaydedilmesi
* [ ] Adres doğrulama
* [ ] Adreslerin koordinata dönüştürülmesi

### Aşama 3 — Harita

* [ ] Harita entegrasyonu
* [ ] Teslimat noktalarının haritada gösterilmesi
* [ ] Kurye konumunun gösterilmesi

### Aşama 4 — Rota optimizasyonu

* [ ] Yol ağı verisinin kullanılması
* [ ] Teslimat sırasının hesaplanması
* [ ] Tek yönlü yolların dikkate alınması
* [ ] Dönüş yasaklarının dikkate alınması
* [ ] U dönüşü yasaklarının dikkate alınması

### Aşama 5 — Dosyadan kargo aktarma

* [ ] CSV desteği
* [ ] Excel desteği
* [ ] Çoklu adres aktarımı

## 💡 Projenin Uzun Vadeli Hedefi

Rotam Belli'nin uzun vadeli amacı yalnızca bir rota gösteren navigasyon uygulaması olmak değil, kuryenin günlük teslimat operasyonunu yöneten bir yardımcı sistem haline gelmektir.

Temel fikir:

**Kargoları yükle → Rotayı oluştur → Teslimata başla → Teslim edilenleri işaretle → Kalan rotayı güncelle.**

---

**Rotam Belli — Daha az dolaş, daha düzenli teslim et.**
