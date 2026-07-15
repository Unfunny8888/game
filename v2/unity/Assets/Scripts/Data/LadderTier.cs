using UnityEngine;

namespace IkhMongol.V2.Data
{
    /// <summary>
    /// Отрядын шатны нэг шат — «N түвшин = N тоглогч»-ийг тоглогдохуйц болгосон хувилбар.
    /// Дизайны баримт дахь шатлалыг тохируулна (1→Ганц, 2→Хос, 4→Отряд, 8→Мянгат, 16→Раид).
    /// </summary>
    [CreateAssetMenu(menuName = "Ikh Mongol/Ladder Tier", fileName = "Tier_")]
    public class LadderTier : ScriptableObject
    {
        public string label = "Отряд";       // Ганц / Хос / Отряд / Мянгат / Раид
        [Min(1)] public int minLevel = 1;
        [Min(1)] public int maxLevel = 10;
        [Range(1, 16)] public int partySize = 1;
        [TextArea] public string era = "";    // тухайн үеийн түүх

        public bool Contains(int level) => level >= minLevel && level <= maxLevel;
    }
}
