import SpriteKit
import UIKit

// MARK: - Математик туслахууд

func clampF(_ v: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat { min(max(v, a), b) }

extension CGPoint {
    func distance(to p: CGPoint) -> CGFloat {
        let dx = Double(x - p.x), dy = Double(y - p.y)
        return CGFloat((dx * dx + dy * dy).squareRoot())
    }
}

func angle(dx: CGFloat, dy: CGFloat) -> CGFloat {
    CGFloat(atan2(Double(dy), Double(dx)))
}

func vecLen(_ dx: CGFloat, _ dy: CGFloat) -> CGFloat {
    let x = Double(dx), y = Double(dy)
    return CGFloat((x * x + y * y).squareRoot())
}

func sinF(_ v: CGFloat) -> CGFloat { CGFloat(sin(Double(v))) }
func cosF(_ v: CGFloat) -> CGFloat { CGFloat(cos(Double(v))) }

// MARK: - Текстур үүсгэгч

enum Tex {
    /// Шугаман градиент текстур (эхний өнгө дээд талд)
    static func linearGradient(size: CGSize, colors: [UIColor]) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()
            guard let grad = CGGradient(colorsSpace: space,
                                        colors: colors.map { $0.cgColor } as CFArray,
                                        locations: nil) else { return }
            cg.drawLinearGradient(grad,
                                  start: .zero,
                                  end: CGPoint(x: 0, y: size.height),
                                  options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        return SKTexture(image: image)
    }
}

// MARK: - Хаптик мэдрэмж

enum Haptics {
    private static let light  = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy  = UIImpactFeedbackGenerator(style: .heavy)
    private static let notify = UINotificationFeedbackGenerator()

    static func hit()     { light.impactOccurred() }
    static func skill()   { medium.impactOccurred() }
    static func crash()   { heavy.impactOccurred() }
    static func levelUp() { notify.notificationOccurred(.success) }
    static func victory() { notify.notificationOccurred(.success) }
    static func defeat()  { notify.notificationOccurred(.error) }
}

// MARK: - UI туслахууд

enum UIFactory {

    /// Алтан өнгийн үндсэн товч
    static func button(text: String, name: String, width: CGFloat = 260, height: CGFloat = 56,
                       primary: Bool = true) -> SKNode {
        let container = SKNode()
        container.name = name

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = primary ? Palette.gold : SKColor(red: 0.30, green: 0.25, blue: 0.15, alpha: 1)
        bg.strokeColor = primary ? Palette.goldDark : SKColor(red: 0.15, green: 0.12, blue: 0.05, alpha: 1)
        bg.lineWidth = 2.5
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = Fonts.heavy
        label.fontSize = height * 0.36
        label.fontColor = primary ? SKColor(red: 0.14, green: 0.08, blue: 0.01, alpha: 1) : Palette.parchment
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        return container
    }

    static func label(_ text: String, font: String = Fonts.bold, size: CGFloat = 16,
                      color: SKColor = Palette.parchment) -> SKLabelNode {
        let l = SKLabelNode(text: text)
        l.fontName = font
        l.fontSize = size
        l.fontColor = color
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }

    static func multiline(_ text: String, font: String = Fonts.demi, size: CGFloat = 12,
                          color: SKColor = Palette.dim, width: CGFloat = 300) -> SKLabelNode {
        let l = label(text, font: font, size: size, color: color)
        l.numberOfLines = 0
        l.preferredMaxLayoutWidth = width
        l.lineBreakMode = .byWordWrapping
        return l
    }

    /// Товч дээр дарагдсан эсэхийг шалгах — node-ийн нэрээр
    static func nodeName(at point: CGPoint, in scene: SKScene) -> String? {
        for node in scene.nodes(at: point) {
            if let n = node.name { return n }
        }
        return nil
    }
}
