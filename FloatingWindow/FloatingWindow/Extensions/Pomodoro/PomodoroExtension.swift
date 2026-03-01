import SwiftUI

@MainActor
class PomodoroExtension: FloatingExtension {
    let id = "pomodoro"
    let displayName = "Pomodoro Timer"
    let icon = "timer"
    @Published var isEnabled = false
    let preferredSize = CGSize(width: 340, height: 80)

    let state = PomodoroState()

    func makeView() -> some View {
        PomodoroView()
            .environmentObject(state)
    }
}
