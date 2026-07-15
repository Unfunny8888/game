# App Store-д тавих иж бүрдэл — Их Монгол

Энэ баримт нь **Их Монгол**-ыг App Store-д илгээхэд шаардлагатай бүх зүйлийг агуулна:
бэлэн байдлын шалгалт, дэлгүүрийн бичвэр (Монгол + Англи), нууцлал ба насны
ангиллын хариултууд, дэлгэцийн зураг, алхам алхмаар илгээх заавар.

> **Гол:** Кодын хувьд бэлэн. Танаас шаардагдах цорын ганц зүйл бол **Xcode дотор
> өөрийн Team-ээ сонгож гарын үсэг зурах** (Signing & Capabilities). Бусад нь бэлэн.

---

## 1. Бэлэн байдлын шалгалт (аудит хийсэн)

| Зүйл | Төлөв | Тэмдэглэл |
|---|---|---|
| Bundle ID | ✅ `mn.ikhmongol.tulaan` | App Store Connect дээр ижил байхаар үүсгэнэ |
| Хувилбар / Build | ✅ 1.0 / 1 | Шинэчлэл бүрд build-ийг нэмэгдүүлнэ |
| Дэлгэцийн нэр | ✅ «Их Монгол» | |
| Чиглэл | ✅ Зөвхөн хэвтээ (landscape) | Тоглоом хэвтээ горимд |
| iOS доод хувилбар | ✅ 15.0 | iPhone X ба дээш бүгд хамрагдана |
| Төхөөрөмж | ✅ iPhone (family 1) | |
| Шифрлэлт | ✅ `ITSAppUsesNonExemptEncryption=false` | Экспортын нийцлийн асуулт автоматаар өнгөрнө |
| Апп дүрс | ✅ 1024×1024 Соёмбо | `Assets.xcassets/AppIcon` |
| Нууцлалын мөр | ✅ Локал сүлжээ | `NSLocalNetworkUsageDescription` бий |
| **Гарын үсэг (Team)** | ⚠️ **Та хийнэ** | Xcode → Signing → өөрийн Team |

---

## 2. Дэлгүүрийн бичвэр (App Store Connect дотор буулгана)

### Анхдагч хэл: **Монгол**

- **Апп нэр (≤30 тэмдэгт):** `Их Монгол: Тулааны талбар`
- **Дэд гарчиг (≤30):** `Чингисийн аян — түүхэн тулаан`
- **Урамшууллын текст (≤170):**
  `Мөнх тэнгэрийн хүчин дор! Чингис хаан болон дайчдыг удирдан, Монголын
  нууц товчоогоор аялж, хот хотыг эзэл. Найзтайгаа 2 тоглогчоор тулалд.`

- **Тайлбар:**
```
Их Монгол — XIII зууны талын туульсыг амилуулсан Монгол сэдэвт тулааны адал явдал.

Тэмүжингээс Чингис хаан хүртэлх замыг Монголын нууц товчоогоор дагаж, тал
нутгийн овог аймгуудыг нэгтгэн, Хорезмын их хотуудыг эзэлнэ.

⚔️ 7 домогт баатар — Тэмүжин, Зэв, Сүбээдэй, Мухулай, Боорчи, Хасар, Чингис хаан
🏹 Хялбар ML маягийн удирдлага — хуруугаа хөдөлгөж, довтол
🗺️ Задгай талбарын аян — дайсны бууц, quest заагч, эзлэлтийн мөчлөг
🤝 Нөхдийн отряд — жанжид тантай хамт байлдана
👥 2 ТОГЛОГЧ — найзтайгаа нэг дэлгэц дээр хамтран тоглох
🏕️ Буурь — адуу маллаж, зэвсэг давтаж, отрядаа хүчирхэгжүүл
📜 Түүхэн сургалт — жинхэнэ он, хот, жанжид; хүүхэд, том хүнд зориулав

Мөнх тэнгэрийн хүчин дор — талбарыг эзэгнэ!
```

- **Түлхүүр үг (≤100, таслалаар):**
  `монгол,чингис,тулаан,аян,түүх,mongol,chinggis,khan,rpg,strategy,coop,warrior,steppe`

- **Дэмжлэгийн URL:** _(шаардлагатай — жишээ: GitHub Pages эсвэл энгийн вэб хуудас)_
- **Маркетингийн URL:** _(сонголтоор)_

### Хоёрдогч хэл: **English (U.S.)**

- **Name:** `Ikh Mongol: Battle Arena`
- **Subtitle:** `Genghis Khan — historic war`
- **Promotional Text:**
  `Under the Eternal Blue Sky! Lead Genghis Khan and his warriors through the
  Secret History of the Mongols, conquer cities, and play 2-player co-op.`
- **Description:**
```
Ikh Mongol brings the 13th-century steppe epic to life — a Mongol-themed battle
adventure. Follow Temujin's rise to Genghis Khan through the Secret History of
the Mongols: unite the steppe tribes and conquer the great cities of Khwarezm.

⚔️ 7 legendary heroes — Temujin, Zev, Subedei, Mukhulai, Boorchi, Khasar, Genghis
🏹 Simple Mobile-Legends-style controls
🗺️ Open-field campaign — enemy camps, a quest marker, and a conquest loop
🤝 A warband of generals fights at your side
👥 2-PLAYER local co-op on one screen
🏕️ Camp economy — raise horses, forge weapons, upgrade your warband
📜 Learn real history — true dates, cities and commanders, for kids and adults

Under the Eternal Blue Sky — rule the battlefield!
```
- **Keywords:** `mongol,genghis,khan,battle,war,history,rpg,strategy,coop,steppe,warrior,empire`

---

## 3. Ангилал ба насны зэрэглэл

- **Үндсэн ангилал:** Games → **Action** (эсвэл Adventure)
- **Хоёрдогч:** Games → **Strategy**
- **Насны зэрэглэл (Age Rating асуулгад):**
  - «Cartoon or Fantasy Violence» → **Infrequent/Mild** (хүүхэлдэйн зөөлөн тулаан, цус байхгүй)
  - Бусад бүх ангилал → **None**
  - Үр дүн: **9+** орчим болно.

---

## 4. Апп нууцлал (App Privacy — «шошго»)

Гуравдагч талын SDK, зар сурталчилгаа, аналитик, tracking **байхгүй**. Прогресс нь
зөвхөн төхөөрөмж дээр (UserDefaults) хадгалагдана.

- **Data collection:** `Data Not Collected` гэж сонгож болно (өгөгдөл төхөөрөмжөөс
  гардаггүй).
- **Тэмдэглэл:** Хэрэв Game Center-ийг идэвхтэй ашиглавал Apple-ийн Game Center нь
  тоглогчийн ID-г ашигладаг — энэ нь Apple-ийн систем. Гуравдагч рүү өгөгдөл
  илгээхгүй тул «Not Collected» хэвээр байж болно. Эргэлзвэл «Identifiers →
  Game Center» гэж мэдэгдээрэй.

---

## 5. Дэлгэцийн зураг (шаардлагатай)

App Store хамгийн багадаа **6.7" iPhone**-ийн зураг шаардана. Тоглоом хэвтээ тул
**хэвтээ 2796×1290** хэмжээтэй.

Энэ репозиторийн хажуугийн `scratchpad`-д **бэлэн 5 зураг** үүсгэсэн (тоглоомоос):
1. Цэс — Соёмбо сүлд
2. Аяны тулаан — Чингис + нөхдийн отряд + quest заагч
3. Эзлэлтийн ялалт — алтан баяр хөөр
4. Буурь — адуу/зэвсгийн эдийн засаг
5. 2 тоглогчийн co-op

> Эдгээр нь вэб хувилбараас (ижил график) авсан тул шууд ашиглаж болно. Хамгийн
> сайн нь: жинхэнэ төхөөрөмж/симулятор дээрээс дахин авах (App Store-т илүү «жинхэнэ»).
> Хүсвэл дээр нь товч гарчиг (жишээ «100 ТҮВШИН», «2 ТОГЛОГЧ») нэмж болно.

Хэрэв танд илүү том дэлгэцтэй iPhone (6.9") бол App Store Connect тухайн хэмжээг
бас асууж болзошгүй — Xcode-ийн симулятороос авна.

---

## 6. Илгээх алхмууд

### A. Xcode дээр (Mac)
1. Төслийг нээ → **Signing & Capabilities** → өөрийн **Team**-ээ сонго.
   (`DEVELOPMENT_TEAM` хоосон тул заавал хийнэ.)
2. Bundle ID `mn.ikhmongol.tulaan` эсвэл өөрийнхөөрөө өөрчил (App Store Connect-тэй тааруул).
3. Дээд талын төхөөрөмж сонголтыг **Any iOS Device (arm64)** болго.
4. **Product → Archive**.
5. Organizer нээгдэнэ → **Distribute App → App Store Connect → Upload**.

### B. App Store Connect дээр (appstoreconnect.apple.com)
6. **My Apps → +** → New App:
   - Platform: iOS · Name: `Их Монгол: Тулааны талбар`
   - Primary Language: Mongolian · Bundle ID: сонго · SKU: `ikhmongol1`
7. Дээрх **§2 бичвэр**, **§3 ангилал/нас**, **§4 нууцлал**-ыг бөглө.
8. **§5 дэлгэцийн зураг**-ыг байршуул.
9. Build хэсэгт Xcode-оос орж ирсэн build-ийг сонго (боловсруулалт ~10-30 мин).
10. Export Compliance: шифрлэлт байхгүй тул автоматаар өнгөрнө.
11. **Add for Review → Submit**.

### C. TestFlight (санал болгоно — эхлээд өөрөө турш)
- Build орж ирсний дараа **TestFlight** табаас өөрийгөө/найзаа урьж, бодит
  төхөөрөмж дээр туршаад дараа нь review-д илгээ.

---

## 7. Түгээмэл татгалзлаас сэргийлэх

- **4.3 (Spam/давхардал):** өвөрмөц Монгол сэдэв, түүх, co-op — асуудалгүй.
- **2.1 (Гүйцэтгэл):** ослоор унахгүй байх — TestFlight дээр бүрэн турш.
- **Metadata:** дэлгэцийн зураг нь бодит тоглоомтой таарч байх (тааруулсан).
- **Насны зэрэглэл:** тулаан бий тул «None» гэж бүү сонго — «Mild Cartoon Violence».
- **Дэмжлэгийн URL** заавал ажиллаж байх ёстой (энгийн хуудас хангалттай).

---

*Код бэлэн. Дээрх алхмуудыг дагавал review-д илгээх боломжтой. Асуулт гарвал асуу —
дэлгэцийн зурган дээр гарчиг нэмэх, эсвэл дэмжлэгийн хуудас үүсгэхэд туслая.*
