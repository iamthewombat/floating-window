import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var isCompleted: Bool
    var createdAt: Date

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.isCompleted = false
        self.createdAt = Date()
    }
}

@MainActor
class TaskListState: ObservableObject {
    @Published var tasks: [TaskItem] = [] {
        didSet { save() }
    }

    private let storageKey = "taskListItems"

    init() {
        load()
    }

    func addTask(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(TaskItem(text: trimmed), at: 0)
    }

    func toggleTask(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
    }

    func deleteTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    func clearCompleted() {
        tasks.removeAll { $0.isCompleted }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else { return }
        tasks = decoded
    }
}
