using System;
using UnityEngine;

namespace IkhMongol.V2.Gameplay
{
    /// <summary>Амь — хохирол, эдгэрэлт, бамбай, үхэл. V1-ийн dealDamage-тай нийцнэ.</summary>
    public class Health : MonoBehaviour
    {
        [SerializeField] private float maxHp = 850f;
        [SerializeField] private float shield = 0f;

        public float MaxHp => maxHp;
        public float Current { get; private set; }
        public float Shield => shield;
        public bool IsDead { get; private set; }
        public float Fraction => maxHp <= 0f ? 0f : Mathf.Clamp01(Current / maxHp);

        /// <summary>(хохирол авсан) — HUD, эффектэд ашиглана.</summary>
        public event Action<float> Damaged;
        /// <summary>(эх сурвалж) — үхэл.</summary>
        public event Action<GameObject> Died;

        public void Configure(float newMaxHp)
        {
            maxHp = Mathf.Max(1f, newMaxHp);
            Current = maxHp;
            IsDead = false;
        }

        private void Awake()
        {
            if (Current <= 0f) Current = maxHp;
        }

        public void TakeDamage(float amount, GameObject source = null)
        {
            if (IsDead || amount <= 0f) return;

            if (shield > 0f)
            {
                float absorbed = Mathf.Min(shield, amount);
                shield -= absorbed;
                amount -= absorbed;
                if (amount <= 0f) return;
            }

            Current = Mathf.Max(0f, Current - amount);
            Damaged?.Invoke(amount);

            if (Current <= 0f)
            {
                IsDead = true;
                Died?.Invoke(source);
            }
        }

        public void Heal(float amount)
        {
            if (IsDead || amount <= 0f) return;
            Current = Mathf.Min(maxHp, Current + amount);
        }

        public void AddShield(float amount) => shield = Mathf.Max(shield, amount);
    }
}
