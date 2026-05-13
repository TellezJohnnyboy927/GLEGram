import Foundation
import UIKit

/// SF Symbol-backed icons used by the AI tab. Each property returns a
/// pre-configured `UIImage` template ready to be tinted.
enum MQAIIcons {
    static var history: UIImage? {
        return UIImage(systemName: "clock.arrow.circlepath")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var profile: UIImage? {
        return UIImage(systemName: "person.crop.circle")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var attach: UIImage? {
        return UIImage(systemName: "photo.on.rectangle")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var globe: UIImage? {
        return UIImage(systemName: "globe")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var modelGlyph: UIImage? {
        return UIImage(systemName: "cloud.fill")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var send: UIImage? {
        return UIImage(systemName: "arrow.up")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var tabIcon: UIImage? {
        return UIImage(systemName: "sparkles")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var tabIconFilled: UIImage? {
        return UIImage(systemName: "sparkles")?
            .withRenderingMode(.alwaysTemplate)
    }

    static var checkmark: UIImage? {
        return UIImage(systemName: "checkmark")?
            .withRenderingMode(.alwaysTemplate)
    }
}
