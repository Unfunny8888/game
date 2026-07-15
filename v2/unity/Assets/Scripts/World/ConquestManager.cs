using System;
using System.Collections.Generic;
using UnityEngine;
using IkhMongol.V2.Data;

namespace IkhMongol.V2.World
{
    /// <summary>
    /// Эзлэлтийн мөчлөгийн төлөвт машин (дизайны баримт дахь гол эргэлт):
    /// Эзлэх → Буурьших → Цуглах → Мородох → (дараагийн хот).
    /// </summary>
    public enum ConquestPhase { Assault, Settle, Regroup, March }

    public class ConquestManager : MonoBehaviour
    {
        [Header("Аяны хотууд (түүхэн дараалал)")]
        [SerializeField] private List<CityLevel> cities = new();
        [SerializeField] private int currentIndex = 0;

        [Header("Отряд")]
        [Tooltip("Одоо холбогдсон/амьд отрядын гишүүд")]
        [SerializeField] private int partyPresent = 1;

        public ConquestPhase Phase { get; private set; } = ConquestPhase.Assault;
        public CityLevel Current => (currentIndex >= 0 && currentIndex < cities.Count) ? cities[currentIndex] : null;

        public event Action<CityLevel> CityConquered;
        public event Action<ConquestPhase> PhaseChanged;
        public event Action AllCitiesConquered;

        // --- Гадны дуудлагууд ---

        /// <summary>Хот дахь бүх хамгаалалт унасан үед (тугийн уналт) дуудна.</summary>
        public void OnCityDefensesFallen()
        {
            if (Phase != ConquestPhase.Assault) return;
            SetPhase(ConquestPhase.Settle);
            CityConquered?.Invoke(Current);
        }

        /// <summary>Эзэлсэн хотод буурьшиж дуусаад (засвар, дархлал) дуудна.</summary>
        public void OnSettled()
        {
            if (Phase != ConquestPhase.Settle) return;
            SetPhase(ConquestPhase.Regroup);
        }

        /// <summary>Отрядын гишүүн ирэх/явах бүрд шинэчилнэ.</summary>
        public void UpdatePartyPresent(int count)
        {
            partyPresent = Mathf.Max(0, count);
            TryMarch();
        }

        /// <summary>Тоглогчид «Мородох» товч дарахад — бүгд цугласан эсэхийг шалгана.</summary>
        public void RequestMarch() => TryMarch();

        // --- Дотоод ---

        private void TryMarch()
        {
            if (Phase != ConquestPhase.Regroup) return;
            CityLevel next = (currentIndex + 1 < cities.Count) ? cities[currentIndex + 1] : null;
            int needed = next != null ? next.requiredParty : 1;

            // Дараагийн хот бүх отрядыг шаардвал бүгд цугартал хүлээнэ.
            if (partyPresent < needed) return;

            SetPhase(ConquestPhase.March);
            AdvanceToNextCity();
        }

        private void AdvanceToNextCity()
        {
            if (currentIndex + 1 >= cities.Count)
            {
                AllCitiesConquered?.Invoke();
                return;
            }
            currentIndex++;
            SetPhase(ConquestPhase.Assault);   // шинэ хот = шинэ түвшин
        }

        private void SetPhase(ConquestPhase p)
        {
            if (Phase == p) return;
            Phase = p;
            PhaseChanged?.Invoke(p);
        }
    }
}
