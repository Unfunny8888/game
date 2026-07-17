using UnityEngine;
using IkhMongol.V2.Gameplay;

namespace IkhMongol.V2.Bootstrap
{
    /// <summary>
    /// Энгийн дайсны зан төлөв (эхлэлийн туршилтад): баатар руу ойртож, зайд
    /// ормогц цохино. Жинхэнэ V2-д үүнийг отряд/бууцны AI-гаар солино.
    /// </summary>
    [RequireComponent(typeof(Health))]
    public class EnemyAgent : MonoBehaviour
    {
        private HeroController _target;
        private Health _targetHp;
        private Health _health;
        private float _moveSpeed = 3.2f;
        private float _attackRange = 2.2f;
        private float _damage = 18f;
        private float _attackCd = 1.2f;
        private float _timer;

        public void Init(HeroController target, float moveSpeed, float attackRange, float damage, float attackCd)
        {
            _target = target;
            _targetHp = target != null ? target.GetComponent<Health>() : null;
            _moveSpeed = moveSpeed;
            _attackRange = attackRange;
            _damage = damage;
            _attackCd = attackCd;
        }

        private void Awake() => _health = GetComponent<Health>();

        private void Update()
        {
            if (_health.IsDead) { Destroy(gameObject, 0.1f); return; }
            if (_target == null || _targetHp == null || _targetHp.IsDead) return;

            Vector3 to = _target.transform.position - transform.position;
            to.y = 0f;
            float dist = to.magnitude;

            if (dist > _attackRange)
            {
                transform.position += to.normalized * _moveSpeed * Time.deltaTime;
                if (to.sqrMagnitude > 0.001f)
                    transform.rotation = Quaternion.Slerp(transform.rotation,
                        Quaternion.LookRotation(to), 8f * Time.deltaTime);
            }
            else
            {
                _timer -= Time.deltaTime;
                if (_timer <= 0f)
                {
                    _timer = _attackCd;
                    _targetHp.TakeDamage(_damage, gameObject);
                }
            }
        }
    }
}
