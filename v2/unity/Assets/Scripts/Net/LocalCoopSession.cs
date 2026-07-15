using System;
using System.Collections.Generic;

namespace IkhMongol.V2.Net
{
    /// <summary>
    /// Нэг төхөөрөмж дээрх «хуурамч» co-op сесс — сүлжээгүйгээр логикоо турших stub.
    /// Босоо зүсэлтэд эхлээд үүнийг ашиглаж, дараа нь жинхэнэ netcode (NGO/Mirror)-оор солино.
    /// </summary>
    public class LocalCoopSession : ICoopSession
    {
        private readonly List<CoopPeer> _peers = new();

        public bool IsHost { get; private set; }
        public bool IsConnected { get; private set; }
        public IReadOnlyCollectionLike Peers => new PeerList(_peers);

        public event Action<CoopPeer> PeerJoined;
        public event Action<CoopPeer> PeerLeft;

        public void HostGame(int maxParty)
        {
            IsHost = true;
            IsConnected = true;
            var self = new CoopPeer { id = 0, name = "Хост", heroIndex = 0 };
            _peers.Add(self);
            PeerJoined?.Invoke(self);
        }

        public void JoinGame(string joinCode)
        {
            // Локал stub — жинхэнэ холболт байхгүй.
            IsHost = false;
            IsConnected = true;
        }

        public void Leave()
        {
            IsConnected = false;
            _peers.Clear();
        }

        public void SendInput(PlayerInput input) { /* локал: шууд симуляцид өгнө */ }
        public void BroadcastSnapshot(WorldSnapshot snapshot) { /* локал: цацах шаардлагагүй */ }

        /// <summary>Туршилтад: хиймэл отрядын гишүүн нэмнэ.</summary>
        public void DebugAddBot(string name, int heroIndex)
        {
            var p = new CoopPeer { id = (ulong)(_peers.Count), name = name, heroIndex = heroIndex };
            _peers.Add(p);
            PeerJoined?.Invoke(p);
        }

        private class PeerList : IReadOnlyCollectionLike
        {
            private readonly List<CoopPeer> _src;
            public PeerList(List<CoopPeer> src) { _src = src; }
            public int Count => _src.Count;
            public IEnumerator<CoopPeer> GetEnumerator() => _src.GetEnumerator();
        }
    }
}
