import Foundation

public enum AI {
    public static func configure(_ block: (AIConfiguration) -> Void) {
        let config = AIConfiguration(registry: .shared)
        block(config)
    }
}
