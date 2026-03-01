import AppKit
import Foundation
import Combine

enum PomodoroPhase: String {
    case idle = "Ready"
    case work = "Focus"
    case breaking = "Break"
}

@MainActor
class PomodoroState: ObservableObject {
    @Published var phase: PomodoroPhase = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var completedRounds: Int = 0

    @Published var workDuration: TimeInterval = 25 * 60 {
        didSet {
            UserDefaults.standard.set(workDuration, forKey: "pomodoroWorkDuration")
            if phase == .idle { timeRemaining = workDuration }
        }
    }

    @Published var breakDuration: TimeInterval = 5 * 60 {
        didSet {
            UserDefaults.standard.set(breakDuration, forKey: "pomodoroBreakDuration")
        }
    }

    private var timer: Timer?

    init() {
        let savedWork = UserDefaults.standard.double(forKey: "pomodoroWorkDuration")
        let savedBreak = UserDefaults.standard.double(forKey: "pomodoroBreakDuration")
        if savedWork > 0 { workDuration = savedWork }
        if savedBreak > 0 { breakDuration = savedBreak }
        timeRemaining = workDuration
    }

    var progress: Double {
        let total: TimeInterval
        switch phase {
        case .idle: total = workDuration
        case .work: total = workDuration
        case .breaking: total = breakDuration
        }
        guard total > 0 else { return 0 }
        return 1.0 - (timeRemaining / total)
    }

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        if phase == .idle {
            phase = .work
            timeRemaining = workDuration
        }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        phase = .idle
        timeRemaining = workDuration
        completedRounds = 0
    }

    func skip() {
        pause()
        transitionPhase()
    }

    private func tick() {
        guard timeRemaining > 0 else { return }
        timeRemaining -= 1
        if timeRemaining <= 0 {
            playCompletionSound()
            pause()
            transitionPhase()
        }
    }

    private func transitionPhase() {
        switch phase {
        case .idle:
            break
        case .work:
            completedRounds += 1
            phase = .breaking
            timeRemaining = breakDuration
        case .breaking:
            phase = .work
            timeRemaining = workDuration
        }
    }

    private func playCompletionSound() {
        NSSound.beep()
        // Also play the system "Glass" sound for a more pleasant alert
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
    }
}
