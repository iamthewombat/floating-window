import SwiftUI

@MainActor
class ClaudeUsageExtension: FloatingExtension {
    let id = "claude-usage"
    let displayName = "Claude Usage"
    let icon = "chart.bar"
    @Published var isEnabled = false
    let preferredSize = CGSize(width: 420, height: 500)

    func makeView() -> some View {
        ClaudeUsageView()
    }
}
