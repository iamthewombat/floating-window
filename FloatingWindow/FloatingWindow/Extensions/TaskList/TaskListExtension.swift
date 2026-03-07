import SwiftUI

@MainActor
class TaskListExtension: FloatingExtension {
    let id = "tasklist"
    let displayName = "Task List"
    let icon = "checklist"
    @Published var isEnabled = false
    let preferredSize = CGSize(width: 340, height: 250)

    let state = TaskListState()

    func makeView() -> some View {
        TaskListView()
            .environmentObject(state)
    }
}
