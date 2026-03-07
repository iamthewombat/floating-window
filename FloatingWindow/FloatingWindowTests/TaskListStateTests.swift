import XCTest
@testable import FloatingWindow

@MainActor
final class TaskListStateTests: XCTestCase {
    var state: TaskListState!

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: "taskListItems")
        state = TaskListState()
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "taskListItems")
    }

    // MARK: - Initial State

    func testInitiallyEmpty() {
        XCTAssertTrue(state.tasks.isEmpty)
    }

    // MARK: - Add Tasks

    func testAddTask() {
        state.addTask("Buy groceries")
        XCTAssertEqual(state.tasks.count, 1)
        XCTAssertEqual(state.tasks[0].text, "Buy groceries")
        XCTAssertFalse(state.tasks[0].isCompleted)
    }

    func testAddMultipleTasks() {
        state.addTask("Task 1")
        state.addTask("Task 2")
        state.addTask("Task 3")
        XCTAssertEqual(state.tasks.count, 3)
    }

    func testNewTasksAddedAtTop() {
        state.addTask("First")
        state.addTask("Second")
        XCTAssertEqual(state.tasks[0].text, "Second")
        XCTAssertEqual(state.tasks[1].text, "First")
    }

    func testAddEmptyTaskIgnored() {
        state.addTask("")
        XCTAssertTrue(state.tasks.isEmpty)
    }

    func testAddWhitespaceOnlyTaskIgnored() {
        state.addTask("   ")
        XCTAssertTrue(state.tasks.isEmpty)
    }

    func testAddTaskTrimsWhitespace() {
        state.addTask("  Hello world  ")
        XCTAssertEqual(state.tasks[0].text, "Hello world")
    }

    // MARK: - Toggle Tasks

    func testToggleTaskCompletes() {
        state.addTask("Test")
        let id = state.tasks[0].id
        state.toggleTask(id)
        XCTAssertTrue(state.tasks[0].isCompleted)
    }

    func testToggleTaskUncompletes() {
        state.addTask("Test")
        let id = state.tasks[0].id
        state.toggleTask(id)
        state.toggleTask(id)
        XCTAssertFalse(state.tasks[0].isCompleted)
    }

    func testToggleNonexistentTaskNoOp() {
        state.addTask("Test")
        state.toggleTask(UUID()) // random ID
        XCTAssertFalse(state.tasks[0].isCompleted)
    }

    // MARK: - Delete Tasks

    func testDeleteTask() {
        state.addTask("To delete")
        let id = state.tasks[0].id
        state.deleteTask(id)
        XCTAssertTrue(state.tasks.isEmpty)
    }

    func testDeleteSpecificTask() {
        state.addTask("Keep")
        state.addTask("Delete me")
        let deleteId = state.tasks[0].id // "Delete me" is at top
        state.deleteTask(deleteId)
        XCTAssertEqual(state.tasks.count, 1)
        XCTAssertEqual(state.tasks[0].text, "Keep")
    }

    func testDeleteNonexistentTaskNoOp() {
        state.addTask("Test")
        state.deleteTask(UUID())
        XCTAssertEqual(state.tasks.count, 1)
    }

    // MARK: - Clear Completed

    func testClearCompleted() {
        state.addTask("Done 1")
        state.addTask("Not done")
        state.addTask("Done 2")
        state.toggleTask(state.tasks[0].id) // "Done 2"
        state.toggleTask(state.tasks[2].id) // "Done 1"
        state.clearCompleted()
        XCTAssertEqual(state.tasks.count, 1)
        XCTAssertEqual(state.tasks[0].text, "Not done")
    }

    func testClearCompletedWhenNoneCompleted() {
        state.addTask("Task 1")
        state.addTask("Task 2")
        state.clearCompleted()
        XCTAssertEqual(state.tasks.count, 2)
    }

    func testClearCompletedWhenAllCompleted() {
        state.addTask("Task 1")
        state.addTask("Task 2")
        state.toggleTask(state.tasks[0].id)
        state.toggleTask(state.tasks[1].id)
        state.clearCompleted()
        XCTAssertTrue(state.tasks.isEmpty)
    }

    // MARK: - Persistence

    func testTasksPersistToUserDefaults() {
        state.addTask("Persistent task")
        let data = UserDefaults.standard.data(forKey: "taskListItems")
        XCTAssertNotNil(data)
    }

    func testTasksRestoredFromUserDefaults() {
        state.addTask("Task A")
        state.addTask("Task B")
        state.toggleTask(state.tasks[0].id) // complete "Task B"

        // Create a new state that should restore from UserDefaults
        let restored = TaskListState()
        XCTAssertEqual(restored.tasks.count, 2)
        XCTAssertEqual(restored.tasks[0].text, "Task B")
        XCTAssertTrue(restored.tasks[0].isCompleted)
        XCTAssertEqual(restored.tasks[1].text, "Task A")
        XCTAssertFalse(restored.tasks[1].isCompleted)
    }

    // MARK: - TaskItem Model

    func testTaskItemHasUniqueID() {
        let task1 = TaskItem(text: "A")
        let task2 = TaskItem(text: "A")
        XCTAssertNotEqual(task1.id, task2.id)
    }

    func testTaskItemDefaultNotCompleted() {
        let task = TaskItem(text: "Test")
        XCTAssertFalse(task.isCompleted)
    }

    func testTaskItemHasCreatedDate() {
        let before = Date()
        let task = TaskItem(text: "Test")
        let after = Date()
        XCTAssertTrue(task.createdAt >= before)
        XCTAssertTrue(task.createdAt <= after)
    }

    func testTaskItemCodable() throws {
        let original = TaskItem(text: "Codable test")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
