# Их Монгол V2 — эхлэлийн багц (starter kit)

Энэ хавтас нь **V2** — *Mobile Legends маягийн стилизацдсан 3D, co-op survival-RPG* —
эхлүүлэх кодын суурь ба төлөвлөгөө. V1 (веб `../web`, iOS `../ios`) хэвээр ажиллана;
V2 бол Unity дээрх шинэ хувилбар.

## Юу шийдэгдсэн бэ
- **График:** Mobile Legends маягийн дээрээс харсан (isometric) стилизацдсан 3D — фотореал биш.
- **Хөдөлгүүр:** Unity (2022.3 LTS буюу шинэ), **Unity Personal (үнэгүй)**.
- **Netcode:** **Netcode for GameObjects + Unity Relay (UGS)** — үнэгүй эхэлдэг, эрх мэдэлт хост, сервергүй.
- **Монетизаци:** **зөвхөн гоо сайхны скин** (дээл/хуяг/морь/зэвсгийн харагдац) — хүч зарахгүй, шударга.
- **Баг:** ганц үүсгэн байгуулагч, төсөв бага → V1-ээр үзэгч татаж, V2-ийн зүсэлтээр ивээн тэтгэгч татна.
- **Платформ:** iOS + Android нэг кодоор.
- **Эхлэл:** нэг хот (Отрар), 2 тоглогчийн co-op босоо зүсэлт (vertical slice).

Дэлгэрэнгүй зорилго, 100 түвшний шат, түүхэн нуруу, эзлэлтийн мөчлөгийг
дизайны баримт бичгээс харна уу (Artifact).

## Энэ багцад юу байгаа вэ
```
v2/
├── README.md              ← энэ файл
├── BUILD_PLAN.md          ← инженерийн эхлэлийн төлөвлөгөө (стек, бүтэц, милестон, 7 баатрын дата)
└── unity/Assets/Scripts/  ← Unity C# гол скриптүүд (drop-in)
    ├── Data/              HeroDefinition, CityLevel, LadderTier (ScriptableObject)
    ├── Gameplay/          HeroController, Health, IsoCameraRig
    ├── Meta/              Loadout (дүр тохируулах)
    ├── World/             ConquestManager (эзлэлтийн мөчлөгийн FSM)
    └── Net/               ICoopSession + LocalCoopSession (netcode интерфейс + stub)
```

> **Тэмдэглэл:** Энэ бол *скрипт суурь*, бүрэн Unity төсөл биш.
> Unity нь `.meta`, `ProjectSettings` зэргийг өөрөө үүсгэдэг тул
> Unity хөгжүүлэгч шинэ 3D (URP) төсөл нээж, `unity/Assets/Scripts/`-ийг
> өөрийн `Assets/Scripts/` дотор хуулж оруулна.

## Хөгжүүлэгч хэрхэн эхлэх вэ
1. Unity Hub → шинэ **3D (URP)** төсөл (2022.3 LTS+).
2. Package Manager → **Netcode for GameObjects**; UGS-д бүртгүүлж **Relay + Lobby** (үнэгүй шат) идэвхжүүлнэ. (`Net/ICoopSession` тусгаарлагдсан тул хожим Photon/Mirror руу солиж болно.)
3. `unity/Assets/Scripts/` доторх скриптүүдийг өөрийн төсөлд хуулна.
4. `BUILD_PLAN.md` дахь «Босоо зүсэлт» милестоныг дага: газар (plane) + баатар prefab +
   `HeroController` + `IsoCameraRig` → тап хийж хөдлөх, автоматаар цохих.
5. Дараа нь `ConquestManager`-ийг нэг хотод холбож эзлэлтийн мөчлөгийг турш.

## V1-тэй холбоо
V2 нь V1-ийн **дизайн, тэнцвэр, өгөгдлийг** үргэлжлүүлнэ: 7 баатар, тэдний 2 чадвар,
хэцүү байдал, түүхэн аяны бүтэц. Эдгээр тоон утгыг `BUILD_PLAN.md`-д хүснэгтээр
хөрвүүлж өгсөн — Unity дахь `HeroDefinition` ассетуудыг эндээс бөглөнө.
