import AVFoundation

/// Дуу авианы менежер — Sounds/ хавтасны WAV файлуудыг тоглуулна
final class Audio {

    static let shared = Audio()

    var muted = false {
        didSet { music?.volume = muted ? 0 : musicVolume }
    }

    private var music: AVAudioPlayer?
    private let musicVolume: Float = 0.4
    private var pools: [String: [AVAudioPlayer]] = [:]
    private var poolIndex: [String: Int] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func url(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
    }

    /// Бүх авиаг урьдчилан ачаалах
    func preload() {
        for name in ["hit", "bow", "skill", "heal", "level", "crash", "drum", "horn", "tap", "win", "lose"] {
            guard pools[name] == nil, let u = url(name) else { continue }
            var players: [AVAudioPlayer] = []
            for _ in 0..<3 {
                if let p = try? AVAudioPlayer(contentsOf: u) {
                    p.prepareToPlay()
                    players.append(p)
                }
            }
            pools[name] = players
            poolIndex[name] = 0
        }
    }

    func play(_ name: String, volume: Float = 1) {
        guard !muted else { return }
        if pools[name] == nil { preload() }
        guard let players = pools[name], !players.isEmpty else { return }
        let i = (poolIndex[name] ?? 0) % players.count
        poolIndex[name] = i + 1
        let p = players[i]
        p.volume = volume
        p.currentTime = 0
        p.play()
    }

    func startMusic() {
        if music == nil, let u = url("music") {
            music = try? AVAudioPlayer(contentsOf: u)
            music?.numberOfLoops = -1
        }
        music?.volume = muted ? 0 : musicVolume
        if music?.isPlaying != true { music?.play() }
    }

    func stopMusic() {
        music?.stop()
    }
}
