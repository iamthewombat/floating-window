import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var state: TaskListState
    @State private var newTaskText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                if state.tasks.contains(where: { $0.isCompleted }) {
                    Button("Clear done") {
                        state.clearCompleted()
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .buttonStyle(.plain)
                }

                Text("\(state.tasks.filter { !$0.isCompleted }.count) left")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Input field
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 14))

                TextField("Add a task...", text: $newTaskText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13))
                    .focused($isInputFocused)
                    .onSubmit {
                        state.addTask(newTaskText)
                        newTaskText = ""
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
            .padding(.horizontal, 8)

            // Task list
            if !state.tasks.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(state.tasks) { task in
                            TaskRowView(task: task) {
                                state.toggleTask(task.id)
                            } onDelete: {
                                state.deleteTask(task.id)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .white.opacity(0.4))
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)

            Text(task.text)
                .font(.system(size: 13))
                .foregroundColor(task.isCompleted ? .white.opacity(0.3) : .white)
                .strikethrough(task.isCompleted)
                .lineLimit(2)

            Spacer()

            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
