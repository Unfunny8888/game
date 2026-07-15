using System;

namespace IkhMongol.V2.Net
{
    /// <summary>Отрядын гишүүн.</summary>
    public struct CoopPeer
    {
        public ulong id;
        public string name;
        public int heroIndex;
    }

    /// <summary>
    /// Co-op сессийн гэрээ. V1-ийн эрх мэдэлт хост загварыг үргэлжлүүлнэ:
    /// зочид оролтоо илгээж, хост тооцоолж, snapshot цацна.
    ///
    /// Энэ интерфейсийн ард Netcode for GameObjects, Mirror эсвэл Photon-ыг
    /// залгаж болно — тоглолтын код зөвхөн энэ гэрээнээс хамаарна.
    /// </summary>
    public interface ICoopSession
    {
        bool IsHost { get; }
        bool IsConnected { get; }
        IReadOnlyCollectionLike Peers { get; }

        event Action<CoopPeer> PeerJoined;
        event Action<CoopPeer> PeerLeft;

        void HostGame(int maxParty);
        void JoinGame(string joinCode);
        void Leave();

        /// <summary>Зочин → хост: тоглогчийн оролт (хөдөлгөөн, довтолгоо, чадвар).</summary>
        void SendInput(PlayerInput input);

        /// <summary>Хост → бүгд: ертөнцийн төлөвийн агшин.</summary>
        void BroadcastSnapshot(WorldSnapshot snapshot);
    }

    /// <summary>Foreach хийхэд хангалттай хөнгөн интерфейс (тодорхой цуглуулгаас хараат бус).</summary>
    public interface IReadOnlyCollectionLike
    {
        int Count { get; }
        System.Collections.Generic.IEnumerator<CoopPeer> GetEnumerator();
    }

    /// <summary>Нэг тоглогчийн оролт (хостод илгээгдэнэ).</summary>
    [Serializable]
    public struct PlayerInput
    {
        public ulong peerId;
        public UnityEngine.Vector3 moveTarget;
        public bool attackHeld;
        public int skillUsed;   // -1 = байхгүй, эсвэл 0/1
    }

    /// <summary>Ертөнцийн товч агшин (хостоос цацагдана). Slice-д энгийн байлгав.</summary>
    [Serializable]
    public struct WorldSnapshot
    {
        public float serverTime;
        public UnitState[] units;
    }

    [Serializable]
    public struct UnitState
    {
        public int netId;
        public UnityEngine.Vector3 position;
        public float hp;
        public byte team;
    }
}
