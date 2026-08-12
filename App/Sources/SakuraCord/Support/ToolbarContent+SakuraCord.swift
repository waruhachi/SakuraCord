import SwiftUI

extension ToolbarContent {
    @ToolbarContentBuilder
    func highVisibilityPriorityIfAvailable() -> some ToolbarContent {
        if #available(macOS 26.1, *) {
            visibilityPriority(.high)
        } else {
            self
        }
    }
}
