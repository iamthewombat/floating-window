import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var state: PomodoroState
    @State private var showSettings = false

    private let workPresets: [(String, TimeInterval)] = [
        ("15 min", 15 * 60),
        ("20 min", 20 * 60),
        ("25 min", 25 * 60),
        ("30 min", 30 * 60),
        ("45 min", 45 * 60),
        ("60 min", 60 * 60),
    ]

    private let breakPresets: [(String, TimeInterval)] = [
        ("3 min", 3 * 60),
        ("5 min", 5 * 60),
        ("10 min", 10 * 60),
        ("15 min", 15 * 60),
    ]

    var body: some View {
        VStack(spacing: 8) {
            if showSettings {
                settingsView
            } else {
                timerView
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.85))
    }

    private var timerView: some View {
        VStack(spacing: 6) {
            // Phase and round indicator
            HStack {
                Text(state.phase.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(phaseColor)

                Spacer()

                if state.completedRounds > 0 {
                    Text("\(state.completedRounds) round\(state.completedRounds == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }

                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // Timer display with progress bar
            HStack(spacing: 12) {
                // Time
                Text(state.timeString)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                // Controls
                HStack(spacing: 8) {
                    Button {
                        state.startPause()
                    } label: {
                        Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(phaseColor.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    if state.phase != .idle {
                        Button {
                            state.skip()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        state.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(phaseColor)
                        .frame(width: geo.size.width * state.progress, height: 4)
                        .animation(.linear(duration: 0.5), value: state.progress)
                }
            }
            .frame(height: 4)
        }
    }

    private var settingsView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Settings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text("Focus")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Picker("", selection: $state.workDuration) {
                    ForEach(workPresets, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .frame(width: 100)
            }

            HStack {
                Text("Break")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Picker("", selection: $state.breakDuration) {
                    ForEach(breakPresets, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .frame(width: 100)
            }
        }
    }

    private var phaseColor: Color {
        switch state.phase {
        case .idle: return .gray
        case .work: return .red
        case .breaking: return .green
        }
    }
}
