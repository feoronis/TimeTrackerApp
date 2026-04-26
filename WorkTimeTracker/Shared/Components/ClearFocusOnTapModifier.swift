import AppKit
import SwiftUI

struct ClearFocusOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        )
    }
}

extension View {
    func clearFocusOnTap() -> some View {
        modifier(ClearFocusOnTapModifier())
    }
}
