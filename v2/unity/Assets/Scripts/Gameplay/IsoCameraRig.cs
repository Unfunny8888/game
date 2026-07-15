using UnityEngine;

namespace IkhMongol.V2.Gameplay
{
    /// <summary>
    /// Mobile Legends маягийн дээрээс харсан (isometric) дагагч камер.
    /// Баатрыг зөөлөн дагаж, тогтмол өнцөг, өндрөөс харна.
    /// </summary>
    public class IsoCameraRig : MonoBehaviour
    {
        [SerializeField] private Transform target;
        [SerializeField] private Vector3 offset = new Vector3(0f, 16f, -11f);
        [SerializeField] private float followLerp = 6f;
        [Tooltip("Харах өнцөг (MLBB ≈ 50–55°)")]
        [SerializeField] private float pitch = 52f;

        private void Start()
        {
            transform.rotation = Quaternion.Euler(pitch, 0f, 0f);
            if (target != null) transform.position = target.position + offset;
        }

        public void SetTarget(Transform t) => target = t;

        private void LateUpdate()
        {
            if (target == null) return;
            Vector3 want = target.position + offset;
            transform.position = Vector3.Lerp(transform.position, want, followLerp * Time.deltaTime);
            transform.rotation = Quaternion.Euler(pitch, 0f, 0f);
        }
    }
}
