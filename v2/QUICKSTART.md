# Их Монгол V2 — Unity дээр эхлэх (Mac)

Энэ бол V2-ийн **эхний playable** руу хамгийн богино зам. ~30 минут.
Ямар ч ассет бэлдэлгүйгээр Play дарж, Mobile Legends маягийн тап-хөдөлгөөн +
авто цохилтыг шууд харна. (Энэ нь Xcode дахь 2D тоглоомоос **тусдаа** шинэ төсөл —
Swift кодыг дахин ашиглахгүй, шинэ 3D суурь.)

## 1. Unity суулгах
1. **Unity Hub** татаж ав → https://unity.com/download (үнэгүй **Personal** лиценз).
2. Hub → **Installs → Install Editor** → хамгийн сүүлийн **LTS** (жишээ Unity 6 LTS).
3. Суулгах явцад **iOS Build Support** (болон Mac дээр **iOS**) сонголтыг чагтал.

## 2. Төсөл үүсгэх
1. Hub → **New Project**.
2. Загвар: **3D (URP)** эсвэл **3D Mobile**. Нэр: `IkhMongolV2`.
3. **Create**.

## 3. Скриптүүдээ оруулах
1. Энэ репозиторийн `v2/unity/Assets/Scripts/` **бүх фолдерыг** хуулаад,
   шинэ төслийн `Assets/` дотор тавь (эсвэл Unity-ийн **Project** цонх руу чир).
2. Unity скриптүүдийг эмхэтгэтэл хэдэн секунд хүлээ. Console-д алдаа байх ёсгүй.

## 4. Playable дүр зураг (0 тохиргоо)
1. **Assets → Scenes** дотор шинэ дүр зураг (**SampleScene** байвал тэрийг ашигла).
2. **GameObject → Create Empty**. Нэрийг `Bootstrap` болго.
3. Тэр объектыг сонгоод **Inspector → Add Component → `GameBootstrap`** нэм.
4. Дээд талын **▶ Play** дар.

Одоо чи харах ёстой:
- Талын ногоон газар, дагагч дээрээс харсан камер.
- Алтан баатар (Тэмүжин) — **газар дээр дарж хөдөлнө**.
- Улаан дайсад ойртож ирнэ; баатар **ойрын дайсныг автоматаар цохино**.
- Зүүн дээд буланд амь харагдана.

> Ажиллаж байвал V2-ийн **босоо зүсэлт** бэлэн боллоо — цаашид жинхэнэ 3D
> загвар, чадвар, хот, онлайн залгана.

## 5. Дараагийн алхмууд (BUILD_PLAN.md дагуу)
1. **Жинхэнэ баатрын дата:** `Assets → Create → Ikh Mongol → Hero Definition` —
   7 баатрын ассет үүсгээд `BUILD_PLAN.md` §5 хүснэгтээс тоо бөглө.
2. **3D загвар:** low-poly баатрын загвар (Synty / Asset Store / Blender) →
   HeroDefinition-ий `modelPrefab`-д холбо. Capsule-ийг сольно.
3. **Чадвар:** `HeroController.UseSkill()` дотор AoE/буфф логик (V1-ийн `castSkill`).
4. **Хотууд:** `Assets → Create → Ikh Mongol → City Level` × 100 (эхлээд 8) →
   `ConquestManager`-т жагсаа.
5. **Онлайн:** **Window → Package Manager → Netcode for GameObjects** +
   **Unity Gaming Services (Relay + Lobby)**. `Net/ICoopSession`-ий ард залгана.

## 6. iOS build
1. **File → Build Settings → iOS → Switch Platform**.
2. **Player Settings** → Bundle ID, чиг (landscape), доод хувилбар iOS 15+.
3. **Build** → Xcode төсөл гарна → Xcode дээр Archive (2D тоглоомтой ижил).

## Тэмдэглэл
- `GameBootstrap` бол зөвхөн **эхлэлийн туршилтын** угсрагч (примитив дүрсээр).
  Жинхэнэ дүр зургийг prefab-аар барихад үүнийг устгана.
- Скриптийн бүтэц: `Data/` (ScriptableObject), `Gameplay/` (хөдөлгөөн/тулаан/камер),
  `World/` (эзлэлтийн мөчлөг), `Meta/` (скин), `Net/` (co-op абстракц),
  `Bootstrap/` (playable угсрагч).
