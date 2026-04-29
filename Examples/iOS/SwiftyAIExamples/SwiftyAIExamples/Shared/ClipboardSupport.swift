import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum ClipboardSupport {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}
