// WildLive — Return-reminder tests.
//
// Two halves. The first exercises LocalExpeditionNotifier.makeRequest,
// which is where the scheduling rules actually live and is pure precisely
// so it can be tested without a notification centre. The second checks that
// the ViewModels reach for the notifier at the right moments, using the
// recording MockExpeditionNotifier rather than the system prompt — a UI or
// unit test that raised the real permission alert would hang.

import XCTest
import UserNotifications
@testable import WildLive

final class ExpeditionReturnRequestTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    func test_schedulesForAnUnresolvedExpeditionStillInTheField() throws {
        let expedition = Expedition.fixture(
            id: "exp-42",
            status: .inProgress,
            outcome: nil,
            endsAt: now.addingTimeInterval(600),
            resolvedAt: nil,
            isDue: false,
            awaitsDecision: false,
            species: nil
        )

        let request = try XCTUnwrap(
            LocalExpeditionNotifier.makeRequest(for: expedition, now: now)
        )

        XCTAssertEqual(request.identifier, "expedition-return.exp-42",
                       "the identifier is derived from the expedition so a "
                       + "re-schedule replaces rather than duplicates")

        let trigger = try XCTUnwrap(request.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertEqual(trigger.timeInterval, 600, accuracy: 0.5)
        XCTAssertFalse(trigger.repeats)
    }

    func test_doesNotScheduleForAnAlreadyResolvedExpedition() {
        let expedition = Expedition.fixture(
            endsAt: now.addingTimeInterval(600),
            resolvedAt: now
        )

        XCTAssertNil(LocalExpeditionNotifier.makeRequest(for: expedition, now: now),
                     "there is nothing to look forward to once it is settled")
    }

    func test_doesNotScheduleWhenTheReturnTimeHasAlreadyPassed() {
        let expedition = Expedition.fixture(
            status: .inProgress,
            outcome: nil,
            endsAt: now.addingTimeInterval(-1),
            resolvedAt: nil,
            isDue: true,
            awaitsDecision: false,
            species: nil
        )

        XCTAssertNil(LocalExpeditionNotifier.makeRequest(for: expedition, now: now),
                     "a reminder for a moment in the past would fire immediately")
    }

    func test_bodyNamesTheHunterAndMapButNeverTheOutcome() throws {
        let expedition = Expedition.fixture(
            status: .inProgress,
            outcome: nil,
            endsAt: now.addingTimeInterval(60),
            resolvedAt: nil,
            isDue: false,
            awaitsDecision: false,
            species: .impala()
        )

        let request = try XCTUnwrap(
            LocalExpeditionNotifier.makeRequest(for: expedition, now: now)
        )

        XCTAssertTrue(request.content.body.contains("Amara Koné"))
        XCTAssertTrue(request.content.body.contains("Kenyan Savanna"))

        // The server has not resolved anything at the moment this fires, so
        // the client cannot know — and must not imply — what was found.
        XCTAssertFalse(request.content.body.contains("Impala"))
        XCTAssertFalse(request.content.body.lowercased().contains("captured"))

        XCTAssertEqual(request.content.userInfo["expeditionID"] as? String, expedition.id)
    }
}

// MARK: - ViewModel integration

final class ExpeditionNotifierWiringTests: XCTestCase {

    func test_dispatchAsksForPermissionThenSchedulesTheReturn() async {
        let notifier = MockExpeditionNotifier()
        let expeditions = FakeExpeditionRepository()
        expeditions.startResult = .success(.fixture(
            id: "exp-7",
            status: .inProgress,
            outcome: nil,
            endsAt: Date().addingTimeInterval(600),
            resolvedAt: nil,
            isDue: false,
            awaitsDecision: false,
            species: nil
        ))

        let viewModel = DispatchConfirmViewModel(
            playerID: "player-1",
            mapID: "map_kenyan_savanna_001",
            hunterID: "hunter_amara_kone_001",
            catalog: FakeCatalogRepository(),
            startExpedition: StartExpedition(
                expeditions: expeditions,
                profiles: FakeProfileRepository()
            ),
            notifier: notifier,
            onDispatched: { _, _ in }
        )

        await viewModel.dispatch()

        let asked = await notifier.authorizationRequests
        let scheduled = await notifier.scheduled
        XCTAssertEqual(asked, 1, "the prompt belongs to the moment of dispatch")
        XCTAssertEqual(scheduled, ["exp-7"])
    }

    func test_resolvingCancelsThePendingReminder() async {
        let notifier = MockExpeditionNotifier()
        let expeditions = FakeExpeditionRepository()
        expeditions.resolveResult = .success(.fixture(id: "exp-7", resolvedAt: Date()))

        let viewModel = ExpeditionDetailViewModel(
            playerID: "player-1",
            expeditionID: "exp-7",
            repository: expeditions,
            resolveExpedition: ResolveExpedition(expeditions: expeditions),
            decideCapture: DecideCapturedAnimal(
                expeditions: expeditions,
                profiles: FakeProfileRepository()
            ),
            notifier: notifier,
            onOverviewChanged: { _ in }
        )

        await viewModel.resolve()

        let cancelled = await notifier.cancelled
        XCTAssertEqual(cancelled, ["exp-7"],
                       "the player beat the alarm to it, so the alarm goes away")
    }

    func test_homeLoadPushesThePendingCountToTheBadge() async {
        let notifier = MockExpeditionNotifier()
        let profiles = FakeProfileRepository(overview: .fixture(pendingDecisions: 3))

        let viewModel = HomeViewModel(
            playerID: "player-1",
            profiles: profiles,
            notifier: notifier,
            onLoaded: { _ in }
        )

        await viewModel.load()

        let badges = await notifier.badgeCounts
        XCTAssertEqual(badges, [3])
    }

    func test_listingExpeditionsResyncsTheRemindersAgainstTheServer() async {
        let notifier = MockExpeditionNotifier()
        let expeditions = FakeExpeditionRepository()
        expeditions.listResult = .success([
            .fixture(id: "exp-1"),
            .fixture(id: "exp-2"),
        ])

        let viewModel = ExpeditionsViewModel(
            playerID: "player-1",
            repository: expeditions,
            notifier: notifier
        )

        await viewModel.load()

        let resyncs = await notifier.resyncs
        XCTAssertEqual(resyncs, [["exp-1", "exp-2"]],
                       "the authoritative list is the cheapest moment to converge")
    }
}
