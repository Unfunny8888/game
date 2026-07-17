using UnityEngine;
using IkhMongol.V2.Data;
using IkhMongol.V2.Gameplay;

namespace IkhMongol.V2.Bootstrap
{
    /// <summary>
    /// «Дарж тоглох» эхлэл — ямар ч ассет бэлдэлгүйгээр бүрэн тоглох боломжтой
    /// талбарыг ажиллах үед угсарна: газар, гэрэл, баатар (Mobile Legends маягийн
    /// тап-хөдөлгөөн + авто цохилт), дагагч камер, хэдэн дайсан.
    ///
    /// АШИГЛАХ: Шинэ хоосон дүр зураг үүсгээд, хоосон GameObject-д энэ скриптийг
    /// нэмээд Play дар. Өөр юу ч тохируулах шаардлагагүй.
    /// Дараа нь HeroDefinition/CityLevel ассет үүсгэж, жинхэнэ 3D загвар холбоно.
    /// </summary>
    public class GameBootstrap : MonoBehaviour
    {
        [Header("Талбар")]
        [SerializeField] private int enemyCount = 6;
        [SerializeField] private float arenaRadius = 22f;

        [Header("Баатрын суурь үзүүлэлт (Тэмүжин)")]
        [SerializeField] private float heroHp = 850f;
        [SerializeField] private float heroDamage = 56f;
        [SerializeField] private float heroMoveSpeed = 6f;
        [SerializeField] private float heroAttackCd = 0.9f;

        private HeroController _hero;

        private void Start()
        {
            EnsureLighting();
            BuildGround();
            Camera cam = EnsureCamera();     // баатрын Awake Camera.main-г уншдаг тул эхэлж бэлдэнэ
            _hero = BuildHero();
            AttachCamera(cam, _hero.transform);
            for (int i = 0; i < enemyCount; i++) BuildEnemy(i);
        }

        // --- Орчин ---

        private void EnsureLighting()
        {
            if (FindObjectOfType<Light>() != null) return;
            var go = new GameObject("Sun");
            var light = go.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.1f;
            light.color = new Color(1f, 0.96f, 0.86f);
            go.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
            RenderSettings.ambientLight = new Color(0.42f, 0.44f, 0.40f);
        }

        private void BuildGround()
        {
            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Steppe";
            ground.transform.localScale = new Vector3(20f, 1f, 20f); // 200×200 нэгж
            ground.transform.position = Vector3.zero;
            Paint(ground, new Color(0.36f, 0.42f, 0.20f));
        }

        // --- Баатар ---

        private HeroController BuildHero()
        {
            var def = ScriptableObject.CreateInstance<HeroDefinition>();
            def.id = "temuujin";
            def.displayName = "Тэмүжин";
            def.role = HeroRole.YoungWarrior;
            def.maxHp = heroHp;
            def.damage = heroDamage;
            def.range = 75f;              // V1 нэгж — HeroController метр рүү хөрвүүлнэ
            def.moveSpeed = heroMoveSpeed;
            def.attackCooldown = heroAttackCd;
            def.skill1.displayName = "Хурц сэлэм";
            def.skill2.displayName = "Өсөх хүч";

            var go = BuildCapsule("Хаан (Тэмүжин)", new Vector3(0f, 1f, 0f),
                                  new Color(0.85f, 0.64f, 0.35f), 1.1f);
            var health = go.AddComponent<Health>();
            health.Configure(heroHp);
            var hero = go.AddComponent<HeroController>();
            hero.ApplyDefinition(def);

            // жижиг «туг» — урд талыг ялгахад
            var nose = GameObject.CreatePrimitive(PrimitiveType.Cube);
            nose.transform.SetParent(go.transform, false);
            nose.transform.localScale = new Vector3(0.25f, 0.25f, 0.6f);
            nose.transform.localPosition = new Vector3(0f, 0.3f, 0.6f);
            Destroy(nose.GetComponent<Collider>());
            Paint(nose, new Color(0.95f, 0.79f, 0.42f));
            return hero;
        }

        // --- Дайсан ---

        private void BuildEnemy(int i)
        {
            float ang = (i / (float)enemyCount) * Mathf.PI * 2f;
            var pos = new Vector3(Mathf.Cos(ang), 1f, Mathf.Sin(ang)) * arenaRadius;
            var go = BuildCapsule($"Дайсан {i + 1}", pos, new Color(0.78f, 0.35f, 0.29f), 1f);
            var health = go.AddComponent<Health>();
            health.Configure(300f);
            var agent = go.AddComponent<EnemyAgent>();
            agent.Init(_hero, moveSpeed: 3.2f, attackRange: 2.2f, damage: 18f, attackCd: 1.2f);
        }

        // --- Камер ---

        private Camera EnsureCamera()
        {
            Camera cam = Camera.main;
            if (cam == null)
            {
                var go = new GameObject("Main Camera");
                go.tag = "MainCamera";
                cam = go.AddComponent<Camera>();
            }
            return cam;
        }

        private void AttachCamera(Camera cam, Transform target)
        {
            var rig = cam.GetComponent<IsoCameraRig>();
            if (rig == null) rig = cam.gameObject.AddComponent<IsoCameraRig>();
            rig.SetTarget(target);
        }

        // --- Туслах ---

        private GameObject BuildCapsule(string name, Vector3 pos, Color color, float scale)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            go.name = name;
            go.transform.position = pos;
            go.transform.localScale = new Vector3(scale, scale, scale);
            Paint(go, color);
            return go;
        }

        private void Paint(GameObject go, Color color)
        {
            var r = go.GetComponent<Renderer>();
            if (r == null) return;
            // URP ба Built-in хоёуланд ажиллах shader сонголт
            var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            var mat = new Material(shader);
            mat.color = color;
            if (mat.HasProperty("_BaseColor")) mat.SetColor("_BaseColor", color);
            r.sharedMaterial = mat;
        }

        private void OnGUI()
        {
            var style = new GUIStyle(GUI.skin.label) { fontSize = 16, fontStyle = FontStyle.Bold };
            style.normal.textColor = Color.white;
            GUI.Label(new Rect(16, 12, 900, 30),
                "Их Монгол V2 — газар дээр дарж хөдөл · ойрын дайсныг автоматаар цохино", style);
            if (_hero != null)
            {
                var hp = _hero.GetComponent<Health>();
                GUI.Label(new Rect(16, 38, 400, 24), $"Амь: {Mathf.CeilToInt(hp.Current)} / {Mathf.CeilToInt(hp.MaxHp)}", style);
            }
        }
    }
}
