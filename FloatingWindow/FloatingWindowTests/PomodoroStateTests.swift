import XCTest
@testable import FloatingWindow

@MainActor
final class PomodoroStateTests: XCTestCase {
    var state: PomodoroState!

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: "pomodoroWorkDuration")
        UserDefaults.standard.removeObject(forKey: "pomodoroBreakDuration")
        state = PomodoroState()
    }

    override func tearDown() async throws {
        state.reset()
        UserDefaults.standard.removeObject(forKey: "pomodoroWorkDuration")
        UserDefaults.standard.removeObject(forKey: "pomodoroBreakDuration")
    }

    // MARK: - Initial State

    func testInitialPhaseIsIdle() {
        XCTAssertEqual(state.phase, .idle)
    }

    func testInitialTimeIsWorkDuration() {
        XCTAssertEqual(state.timeRemaining, 25 * 60)
    }

    func testDefaultWorkDuration() {
        XCTAssertEqual(state.workDuration, 25 * 60)
    }

    func testDefaultBreakDuration() {
        XCTAssertEqual(state.breakDuration, 5 * 60)
    }

    func testNotRunningInitially() {
        XCTAssertFalse(state.isRunning)
    }

    func testZeroCompletedRoundsInitially() {
        XCTAssertEqual(state.completedRounds, 0)
    }

    // MARK: - Start / Pause

    func testStartSetsPhaseToWork() {
        state.start()
        XCTAssertEqual(state.phase, .work)
        XCTAssertTrue(state.isRunning)
        state.pause()
    }

    func testStartSetsTimeToWorkDuration() {
        state.start()
        XCTAssertEqual(state.timeRemaining, state.workDuration)
        state.pause()
    }

    func testPauseStopsRunning() {
        state.start()
        XCTAssertTrue(state.isRunning)
        state.pause()
        XCTAssertFalse(state.isRunning)
    }

    func testStartPauseToggles() {
        state.startPause()
        XCTAssertTrue(state.isRunning)
        state.startPause()
        XCTAssertFalse(state.isRunning)
    }

    // MARK: - Reset

    func testResetGoesBackToIdle() {
        state.start()
        state.reset()
        XCTAssertEqual(state.phase, .idle)
        XCTAssertFalse(state.isRunning)
        XCTAssertEqual(state.timeRemaining, state.workDuration)
        XCTAssertEqual(state.completedRounds, 0)
    }

    func testResetClearsCompletedRounds() {
        state.start()
        state.skip() // work -> break, completedRounds = 1
        XCTAssertEqual(state.completedRounds, 1)
        state.reset()
        XCTAssertEqual(state.completedRounds, 0)
    }

    // MARK: - Skip / Phase Transitions

    func testSkipFromWorkGoesToBreak() {
        state.start()
        state.skip()
        XCTAssertEqual(state.phase, .breaking)
        XCTAssertEqual(state.timeRemaining, state.breakDuration)
        XCTAssertFalse(state.isRunning)
    }

    func testSkipFromWorkIncrementsRounds() {
        state.start()
        state.skip()
        XCTAssertEqual(state.completedRounds, 1)
    }

    func testSkipFromBreakGoesToWork() {
        state.start()
        state.skip() // work -> break
        state.skip() // break -> work
        XCTAssertEqual(state.phase, .work)
        XCTAssertEqual(state.timeRemaining, state.workDuration)
    }

    func testSkipFromBreakDoesNotIncrementRounds() {
        state.start()
        state.skip() // work -> break, rounds = 1
        state.skip() // break -> work, rounds still 1
        XCTAssertEqual(state.completedRounds, 1)
    }

    func testSkipPausesTimer() {
        state.start()
        XCTAssertTrue(state.isRunning)
        state.skip()
        XCTAssertFalse(state.isRunning)
    }

    // MARK: - No Auto-Start

    func testTimerDoesNotAutoStartAfterSkip() {
        state.start()
        state.skip() // work -> break
        XCTAssertFalse(state.isRunning)
    }

    func testMultipleSkipsCycleCorrectly() {
        state.start()
        state.skip() // work -> break (round 1)
        state.skip() // break -> work
        state.start()
        state.skip() // work -> break (round 2)
        state.skip() // break -> work
        XCTAssertEqual(state.completedRounds, 2)
        XCTAssertEqual(state.phase, .work)
    }

    // MARK: - Progress

    func testProgressIsZeroAtStart() {
        XCTAssertEqual(state.progress, 0.0, accuracy: 0.001)
    }

    func testProgressAtIdle() {
        XCTAssertEqual(state.progress, 0.0, accuracy: 0.001)
    }

    // MARK: - Time String

    func testTimeStringFormat() {
        state.start()
        // 25:00
        XCTAssertEqual(state.timeString, "25:00")
        state.pause()
    }

    func testTimeStringFormatWithSeconds() {
        state.start()
        // Manually set time for testing
        state.pause()
        // After skip to break: should be 05:00
        state.skip()
        XCTAssertEqual(state.timeString, "05:00")
    }

    // MARK: - Configurable Durations

    func testWorkDurationPersists() {
        state.workDuration = 30 * 60
        XCTAssertEqual(UserDefaults.standard.double(forKey: "pomodoroWorkDuration"), 30 * 60)
    }

    func testBreakDurationPersists() {
        state.breakDuration = 10 * 60
        XCTAssertEqual(UserDefaults.standard.double(forKey: "pomodoroBreakDuration"), 10 * 60)
    }

    func testChangingWorkDurationUpdatesTimeWhenIdle() {
        XCTAssertEqual(state.phase, .idle)
        state.workDuration = 45 * 60
        XCTAssertEqual(state.timeRemaining, 45 * 60)
    }

    func testRestoredDurationsFromDefaults() {
        UserDefaults.standard.set(30.0 * 60, forKey: "pomodoroWorkDuration")
        UserDefaults.standard.set(10.0 * 60, forKey: "pomodoroBreakDuration")
        let restored = PomodoroState()
        XCTAssertEqual(restored.workDuration, 30 * 60)
        XCTAssertEqual(restored.breakDuration, 10 * 60)
        XCTAssertEqual(restored.timeRemaining, 30 * 60)
    }
}
