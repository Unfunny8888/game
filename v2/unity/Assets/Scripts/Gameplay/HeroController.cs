using UnityEngine;
using IkhMongol.V2.Data;

namespace IkhMongol.V2.Gameplay
{
    /// <summary>
    /// Mobile Legends маягийн удирдлага: газарт тап хийж хөдлөх, ойрын дайсныг
    /// автоматаар цохих, чадвар ашиглах. Энгийн байхаар зориулж legacy Input ашигласан —
    /// шинэ Input System руу амархан солино.
    ///
    /// Шаардлага: тэгш газар y≈0. Дайснууд "Enemy" таг эсвэл давхаргатай.
    /// </summary>
    [RequireComponent(typeof(Health))]
    public class HeroController : MonoBehaviour
    {
        [Header("Тодорхойлолт")]
        public HeroDefinition definition;

        [Header("Хөдөлгөөн")]
        [SerializeField] private float turnSpeed = 14f;
        [SerializeField] private LayerMask groundMask = ~0;
        [SerializeField] private LayerMask enemyMask = ~0;

        [Header("Тап заагч (сонголт)")]
        [SerializeField] private GameObject moveMarkerPrefab;

        private Health _health;
        private Camera _cam;
        private Vector3 _destination;
        private bool _hasDestination;
        private float _attackTimer;

        // Ажиллаж буй утга (definition-оос хуулна — түвшин ахихад өөрчлөгдөж болно)
        private float _moveSpeed = 6f;
        private float _range = 2.5f;
        private float _damage = 56f;
        private float _attackCd = 0.9f;

        private void Awake()
        {
            _health = GetComponent<Health>();
            _cam = Camera.main;
            if (definition != null) ApplyDefinition(definition);
        }

        public void ApplyDefinition(HeroDefinition def)
        {
            definition = def;
            _moveSpeed = def.moveSpeed;
            _range = Mathf.Max(1.5f, def.range * 0.033f); // V1 нэгжийг метр рүү ойролцоо хөрвүүлнэ
            _damage = def.damage;
            _attackCd = def.attackCooldown;
            _health.Configure(def.maxHp);
            _destination = transform.position;
        }

        private void Update()
        {
            if (_health.IsDead) return;
            ReadInput();

            Health target = FindNearestEnemy();
            if (target != null && DistanceTo(target) <= _range)
            {
                _hasDestination = false;               // байлдааны зайд зогсоно
                FaceToward(target.transform.position);
                TickAttack(target);
            }
            else
            {
                MoveTowardDestination();
            }

            _attackTimer -= Time.deltaTime;
        }

        // --- Оролт ---
        private void ReadInput()
        {
            bool pressed = Input.GetMouseButtonDown(0);
#if UNITY_IOS || UNITY_ANDROID
            pressed = Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Began;
#endif
            if (!pressed) return;

            Vector3 screen = Input.mousePosition;
            if (Input.touchCount > 0) screen = Input.GetTouch(0).position;

            Ray ray = _cam.ScreenPointToRay(screen);
            var ground = new Plane(Vector3.up, Vector3.zero);
            if (ground.Raycast(ray, out float dist))
            {
                _destination = ray.GetPoint(dist);
                _hasDestination = true;
                if (moveMarkerPrefab != null)
                    Instantiate(moveMarkerPrefab, _destination, Quaternion.identity);
            }
        }

        // --- Хөдөлгөөн ---
        private void MoveTowardDestination()
        {
            if (!_hasDestination) return;
            Vector3 flat = new Vector3(_destination.x, transform.position.y, _destination.z);
            Vector3 to = flat - transform.position;
            if (to.sqrMagnitude < 0.04f) { _hasDestination = false; return; }

            FaceToward(flat);
            transform.position += to.normalized * _moveSpeed * Time.deltaTime;
        }

        private void FaceToward(Vector3 worldPoint)
        {
            Vector3 dir = worldPoint - transform.position;
            dir.y = 0f;
            if (dir.sqrMagnitude < 0.001f) return;
            Quaternion want = Quaternion.LookRotation(dir);
            transform.rotation = Quaternion.Slerp(transform.rotation, want, turnSpeed * Time.deltaTime);
        }

        // --- Довтолгоо ---
        private void TickAttack(Health target)
        {
            if (_attackTimer > 0f) return;
            _attackTimer = _attackCd;
            target.TakeDamage(_damage, gameObject);
            // TODO: анимацийн триггер + цохилтын VFX/дуу (V1-ийн эффектийг дуурай)
        }

        private Health FindNearestEnemy()
        {
            // Жижиг слайст энгийн overlap; том масштабт spatial-hash / отрядын bucket ашиглана.
            Collider[] hits = Physics.OverlapSphere(transform.position, _range + 6f, enemyMask);
            Health best = null;
            float bestSq = float.MaxValue;
            foreach (var h in hits)
            {
                var hp = h.GetComponentInParent<Health>();
                if (hp == null || hp.IsDead || hp == _health) continue;
                float sq = (hp.transform.position - transform.position).sqrMagnitude;
                if (sq < bestSq) { bestSq = sq; best = hp; }
            }
            return best;
        }

        private float DistanceTo(Health h) =>
            Vector3.Distance(transform.position, h.transform.position);

        /// <summary>HUD-ийн чадварын товчноос дуудна (idx = 0/1).</summary>
        public void UseSkill(int idx)
        {
            if (_health.IsDead || definition == null) return;
            SkillDefinition s = idx == 0 ? definition.skill1 : definition.skill2;
            // TODO: cooldown хяналт, эффект, AoE логик (V1-ийн useSkill-ийг дуурай)
            Debug.Log($"[Hero] Чадвар ашиглав: {s.displayName}");
        }
    }
}
