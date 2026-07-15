using UnityEngine;

namespace IkhMongol.V2.Data
{
    /// <summary>Даалгаврын төрөл — V1-ийн Objective-той нийцнэ.</summary>
    public enum ObjectiveKind { Reach, Collect, Rescue, Slay, Survive, Conquer }

    /// <summary>
    /// Нэг түвшин = нэг түүхэн хот. Түүхэн дарааллаар нээгдэнэ.
    /// Assets → Create → Ikh Mongol → City Level.
    /// </summary>
    [CreateAssetMenu(menuName = "Ikh Mongol/City Level", fileName = "City_")]
    public class CityLevel : ScriptableObject
    {
        [Header("Байршил")]
        [Min(1)] public int levelIndex = 1;
        public string cityName = "Отрар";
        public string year = "1219";
        [TextArea] public string historyNote = "";

        [Header("Тоглолт")]
        public ObjectiveKind objective = ObjectiveKind.Conquer;
        [Tooltip("Энэ хотыг эзлэхэд шаардлагатай хамгийн бага отряд")]
        [Range(1, 16)] public int requiredParty = 1;
        [Tooltip("Дайсны хүчний үржүүлэгч — гүн рүү орох тусам өснө")]
        public float difficultyMultiplier = 1f;

        [Header("Ертөнц")]
        public GameObject cityPrefab;     // хэрэм, сүм, минарет
        public Vector3 worldPosition;     // нийтийн газрын зураг дээрх байрлал
    }
}
