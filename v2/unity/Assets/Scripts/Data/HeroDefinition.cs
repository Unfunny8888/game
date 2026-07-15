using UnityEngine;

namespace IkhMongol.V2.Data
{
    /// <summary>Баатрын үүрэг — V1-ийн ролиудтай нийцнэ.</summary>
    public enum HeroRole { YoungWarrior, Archer, Guardian, General, Skirmisher, Khan }

    /// <summary>Нэг чадварын тодорхойлолт (V1-ийн s1/s2-той нийцнэ).</summary>
    [System.Serializable]
    public class SkillDefinition
    {
        public string displayName = "Чадвар";
        public string shortName = "Чадвар";
        [TextArea] public string description = "";
        [Min(0f)] public float cooldown = 6f;
        public GameObject vfxPrefab;   // сонголтоор — цохилтын эффект
    }

    /// <summary>
    /// Баатрын үндсэн тодорхойлолт. Unity дотор
    /// Assets → Create → Ikh Mongol → Hero Definition гэж ассет үүсгэнэ.
    /// Тоон утгыг BUILD_PLAN.md дахь хүснэгтээс бөглөнө.
    /// </summary>
    [CreateAssetMenu(menuName = "Ikh Mongol/Hero Definition", fileName = "Hero_")]
    public class HeroDefinition : ScriptableObject
    {
        [Header("Таних")]
        public string id = "temuujin";
        public string displayName = "Тэмүжин";
        public HeroRole role = HeroRole.YoungWarrior;
        [Tooltip("Баатрын өнгө / туг")] public Color banner = new Color(0.85f, 0.64f, 0.35f);

        [Header("Суурь үзүүлэлт (V1-ээс)")]
        [Min(1f)] public float maxHp = 850f;
        [Min(0f)] public float damage = 56f;
        [Tooltip("Цохих зай (метр биш, V1-ийн нэгж)")] public float range = 75f;
        [Min(0f)] public float moveSpeed = 6f;         // Unity нэгж/сек (V1-ийн 185 ≈ 6)
        [Min(0.05f)] public float attackCooldown = 0.9f;

        [Header("Чадварууд")]
        public SkillDefinition skill1 = new SkillDefinition();
        public SkillDefinition skill2 = new SkillDefinition();

        [Header("3D дүрс")]
        public GameObject modelPrefab;                 // MLBB маягийн low-poly загвар
        public bool isPremium = false;                 // Чингис хаан = премиум
    }
}
