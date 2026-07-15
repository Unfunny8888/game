using System;
using System.Collections.Generic;
using UnityEngine;

namespace IkhMongol.V2.Meta
{
    /// <summary>Тохируулгын үүр — дизайны баримт дахь слотуудтай нийцнэ.</summary>
    public enum GearSlot { Deel, Armor, Helmet, Mount, Weapon }

    /// <summary>Скины төрөл — гоо сайхан (шударга) vs хүч (тоглолтод нөлөөлнө).</summary>
    public enum SkinKind { Cosmetic, Power }

    /// <summary>Нэг эд зүйл / скин. Assets → Create → Ikh Mongol → Gear Item.</summary>
    [CreateAssetMenu(menuName = "Ikh Mongol/Gear Item", fileName = "Gear_")]
    public class GearItem : ScriptableObject
    {
        public string id;
        public string displayName;
        public GearSlot slot;
        public SkinKind kind = SkinKind.Cosmetic;
        public GameObject visualPrefab;   // 3D хэсэг (дээл, хуяг, дуулга...)

        [Header("Хүчний нөлөө (зөвхөн Power төрөлд)")]
        public float bonusHp;
        public float bonusDamage;
        public float bonusMoveSpeed;
    }

    /// <summary>
    /// Тоглогчийн дүрийн тохируулга. Гоо сайхны скин тоглолтод нөлөөлөхгүй —
    /// «pay-to-win» болохоос сэргийлж, хүчний эд зүйлийг тусад нь барина.
    /// </summary>
    [Serializable]
    public class Loadout
    {
        private readonly Dictionary<GearSlot, GearItem> _equipped = new();

        public void Equip(GearItem item)
        {
            if (item == null) return;
            _equipped[item.slot] = item;
        }

        public GearItem Get(GearSlot slot) =>
            _equipped.TryGetValue(slot, out var item) ? item : null;

        /// <summary>Зөвхөн Power эд зүйлсийн нийлбэр бонус (Cosmetic-ийг тооцохгүй).</summary>
        public (float hp, float dmg, float speed) PowerBonus()
        {
            float hp = 0f, dmg = 0f, spd = 0f;
            foreach (var item in _equipped.Values)
            {
                if (item == null || item.kind != SkinKind.Power) continue;
                hp += item.bonusHp;
                dmg += item.bonusDamage;
                spd += item.bonusMoveSpeed;
            }
            return (hp, dmg, spd);
        }
    }
}
