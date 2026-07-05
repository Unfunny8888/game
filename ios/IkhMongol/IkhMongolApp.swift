import SwiftUI
import SpriteKit

@main
struct IkhMongolApp: App {
    var body: some Scene {
        WindowGroup {
            GameContainerView()
        }
    }
}

struct GameContainerView: View {

    @State private var scene: SKScene = {
        let scene = MenuScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = Palette.night
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, preferredFramesPerSecond: 60)
            .ignoresSafeArea()
            .statusBar(hidden: true)
    }
}
