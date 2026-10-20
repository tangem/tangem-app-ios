//
//  MainScreenPromoSheetProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@MainActor
@Suite("MainScreenPromoSheetProvider")
struct MainScreenPromoSheetProviderTests {
    @Test("Presents the sheet of the ready source and stops every source")
    func presentsReadySource() async {
        await withProvider(managerStates: [.ready]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers.presentedIds == [managers[0].id])
            #expect(managers[0].didStart)
            #expect(managers[0].didStop)
        }
    }

    @Test("Shows the first ready source in priority order and leaves no source running")
    func showsFirstReadySource() async {
        await withProvider(managerStates: [.ready, .ready]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers.presentedIds == [managers[0].id])
            #expect(!managers[1].isRunning)
        }
    }

    @Test("Waits while a higher priority source is preparing, even if a lower one is ready")
    func waitsForHigherPrioritySource() async {
        await withProvider(managerStates: [.preparing, .ready]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()
            #expect(managers.presentedIds.isEmpty)

            managers[0].state.send(.unavailable(.noEligibleContent))
            await drainMainQueue()

            #expect(managers.presentedIds == [managers[1].id])
            #expect(managers[0].skipReasons.isEmpty)
        }
    }

    @Test("A lower priority source does not hold back a ready one above it, even before it reports anything")
    func lowerPrioritySourceDoesNotBlock() async {
        await withProvider(managerStates: [.ready, .preparing, nil]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers.presentedIds == [managers[0].id])
        }
    }

    @Test("A source that reports from a background queue is presented on the main thread")
    func presentsOnMainThreadForBackgroundSource() async {
        await withProvider(managerStates: [.preparing]) { provider, managers, _ in
            provider.onMainScreenAppear()

            nonisolated(unsafe) let state = managers[0].state
            await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    state.send(.ready)
                    continuation.resume()
                }
            }
            await drainMainQueue()

            #expect(managers[0].presentedOnMainThread == true)
        }
    }

    @Test("Presents only once even if states keep changing")
    func presentsOnlyOnce() async {
        await withProvider(managerStates: [.ready]) { provider, managers, _ in
            provider.onMainScreenAppear()
            managers[0].state.send(.ready)
            await drainMainQueue()

            #expect(managers[0].presentCount == 1)
        }
    }

    @Test("When no source is available the highest priority one reports its own reason, once")
    func reportsSingleSkip() async {
        await withProvider(managerStates: [.unavailable(.dataNotReady), .unavailable(.noEligibleContent)]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers.presentedIds.isEmpty)
            #expect(managers[0].skipReasons == [.dataNotReady])
            #expect(managers[1].skipReasons.isEmpty)
        }
    }

    @Test("Releasing the provider before a decision stops the sources")
    func releasingProviderStopsSources() {
        let manager = StubPromoSheetManager(state: .preparing)
        var provider: MainScreenPromoSheetProvider? = makeProvider(managers: [manager])

        provider?.onMainScreenAppear()
        provider = nil

        #expect(manager.didStop)
    }

    @Test("Evaluates only on the first main screen appearance of the process")
    func evaluatesOnlyOnFirstAppearance() async {
        await withProvider(managerStates: [.preparing]) { provider, managers, interactor in
            interactor.didClaimFirstAppearance = true

            provider.onMainScreenAppear()
            managers[0].state.send(.ready)
            await drainMainQueue()

            #expect(!managers[0].didStart)
            #expect(managers.presentedIds.isEmpty)
        }
    }

    @Test("The first main screen appearance is spent even when no source can run")
    func spendsFirstAppearanceWithoutEligibleSources() async {
        await withProvider(managerStates: [.ready]) { provider, managers, interactor in
            managers[0].handlesPresentation = false

            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(interactor.didClaimFirstAppearance)
            #expect(!managers[0].didStart)
        }
    }

    @Test("Each source decides with the presentation settings of this launch")
    func sourcesDecideWithPresentationSettings() async {
        await withProvider(managerStates: [.ready, .ready]) { provider, managers, interactor in
            interactor.markOpenedFromLink()

            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers[0].receivedPresentationSettings.map(\.isOpenedFromLink) == [true])
            #expect(managers[1].receivedPresentationSettings.map(\.isOpenedFromLink) == [true])
        }
    }

    @Test("A source that cannot handle the presentation is neither started nor reported")
    func sourceThatCannotHandlePresentationIsIgnored() async {
        await withProvider(managerStates: [.ready]) { provider, managers, _ in
            managers[0].handlesPresentation = false

            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(!managers[0].didStart)
            #expect(managers.presentedIds.isEmpty)
            #expect(managers[0].skipReasons.isEmpty)
        }
    }

    @Test("A source that cannot handle the presentation gives way to the next one")
    func sourceThatCannotHandlePresentationGivesWay() async {
        await withProvider(managerStates: [.ready, .ready]) { provider, managers, _ in
            managers[0].handlesPresentation = false

            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(!managers[0].didStart)
            #expect(managers.presentedIds == [managers[1].id])
        }
    }

    @Test("The sheet counts as shown only once it appears, and only once")
    func marksShownOnAppearance() async {
        await withProvider(managerStates: [.ready]) { provider, managers, interactor in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(!interactor.hasShownSheet(managerId: managers[0].id))
            #expect(managers[0].shownCount == 0)

            managers[0].appearanceSubject.send()
            managers[0].appearanceSubject.send()

            #expect(interactor.hasShownSheet(managerId: managers[0].id))
            #expect(managers[0].shownCount == 1)
        }
    }

    @Test("A skipped launch does not count as shown")
    func skipDoesNotMarkShown() async {
        await withProvider(managerStates: [.unavailable(.dataNotReady)]) { provider, managers, interactor in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(!interactor.hasShownSheet(managerId: managers[0].id))
        }
    }

    @Test("A sheet the source could not present does not count as shown")
    func unpresentedSheetDoesNotMarkShown() async {
        await withProvider(managerStates: [.ready]) { provider, managers, interactor in
            managers[0].presentsSheet = false

            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers[0].presentCount == 1)
            #expect(!interactor.hasShownSheet(managerId: managers[0].id))
            #expect(managers[0].shownCount == 0)
        }
    }

    @Test("An already shown source is neither started nor reported")
    func alreadyShownSourceIsIgnored() async {
        await withProvider(managerStates: [.ready], shownManagerIndices: [0]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(!managers[0].didStart)
            #expect(managers[0].skipReasons.isEmpty)
            #expect(managers.presentedIds.isEmpty)
        }
    }

    @Test("An already shown source gives way to the next one")
    func alreadyShownSourceGivesWay() async {
        await withProvider(managerStates: [.ready, .ready], shownManagerIndices: [0]) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(managers.presentedIds == [managers[1].id])
        }
    }

    @Test("The variant is read once, as the last step, and handed to the source")
    func readsVariantLast() async {
        let experiment = ExperimentServiceStub(storedVariant: "user_max_apy", isFetched: true)

        await withProvider(managerStates: [.preparing], experiment: experiment) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()
            #expect(experiment.invokedMethods.isEmpty)

            managers[0].state.send(.ready)
            await drainMainQueue()

            #expect(experiment.invokedMethods == [.variant])
            #expect(managers[0].requestedVariants == ["user_max_apy"])
            #expect(managers.presentedIds == [managers[0].id])
        }
    }

    @Test("Variants not fetched for the selected wallet skip without reading the variant")
    func variantsNotFetchedSkips() async {
        let experiment = ExperimentServiceStub(storedVariant: "user_max_apy", isFetched: false)

        await withProvider(managerStates: [.ready], experiment: experiment) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(experiment.invokedMethods.isEmpty)
            #expect(managers[0].skipReasons == [.variantNotReady])
            #expect(managers.presentedIds.isEmpty)
        }
    }

    @Test("No selected wallet skips without reading the variant")
    func noSelectedWalletSkips() async {
        let experiment = ExperimentServiceStub(storedVariant: "user_max_apy", isFetched: true)

        await withProvider(managerStates: [.ready], experiment: experiment, selectedUserWalletId: nil) { provider, managers, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(experiment.invokedMethods.isEmpty)
            #expect(managers[0].skipReasons == [.variantNotReady])
        }
    }

    @Test("A variant the source declines shows nothing and does not count as shown")
    func declinedVariantShowsNothing() async {
        let experiment = ExperimentServiceStub(storedVariant: "control", isFetched: true)

        await withProvider(managerStates: [.ready], experiment: experiment) { provider, managers, interactor in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(experiment.invokedMethods == [.variant])
            #expect(managers.presentedIds.isEmpty)
            #expect(managers[0].skipReasons.isEmpty)
            #expect(!interactor.hasShownSheet(managerId: managers[0].id))
        }
    }

    @Test("A skipped launch never reads the variant")
    func skipNeverReadsVariant() async {
        let experiment = ExperimentServiceStub(storedVariant: "user_max_apy", isFetched: true)

        await withProvider(managerStates: [.unavailable(.dataNotReady)], experiment: experiment) { provider, _, _ in
            provider.onMainScreenAppear()
            await drainMainQueue()

            #expect(experiment.invokedMethods.isEmpty)
        }
    }

    private func withProvider(
        managerStates: [MainScreenPromoSheetManagerState?],
        shownManagerIndices: Set<Int> = [],
        experiment: ExperimentServiceStub = ExperimentServiceStub(storedVariant: "treatment", isFetched: true),
        selectedUserWalletId: UserWalletId? = Self.userWalletId,
        _ operation: (MainScreenPromoSheetProvider, [StubPromoSheetManager], StubPromoSheetInteractor) async -> Void
    ) async {
        let interactor = StubPromoSheetInteractor()
        let managers = managerStates.map { StubPromoSheetManager(state: $0) }
        shownManagerIndices.forEach { interactor.shownManagerIds.insert(managers[$0].id) }
        let provider = makeProvider(
            managers: managers,
            interactor: interactor,
            experiment: experiment,
            selectedUserWalletId: selectedUserWalletId
        )

        await operation(provider, managers, interactor)
    }

    private func makeProvider(
        managers: [StubPromoSheetManager],
        interactor: StubPromoSheetInteractor = StubPromoSheetInteractor(),
        experiment: ExperimentServiceStub = ExperimentServiceStub(storedVariant: "treatment", isFetched: true),
        selectedUserWalletId: UserWalletId? = Self.userWalletId
    ) -> MainScreenPromoSheetProvider {
        MainScreenPromoSheetProvider(
            managers: managers,
            interactor: interactor,
            experimentService: experiment,
            selectedUserWalletId: { selectedUserWalletId }
        )
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    private nonisolated static let userWalletId = UserWalletId(value: Data(repeating: 0x01, count: 32))
}

// MARK: - Stubs

private final class StubPromoSheetInteractor: MainScreenPromoSheetInteractor {
    private(set) var presentationSettings = MainScreenPromoSheetPresentationSettings(isOpenedFromLink: false)
    var didClaimFirstAppearance = false
    var shownManagerIds: Set<String> = []
    private var shownSheetSubscription: AnyCancellable?

    func initialize() {}

    func claimFirstMainScreenAppearance() -> Bool {
        guard !didClaimFirstAppearance else {
            return false
        }

        didClaimFirstAppearance = true
        return true
    }

    func hasShownSheet(managerId: String) -> Bool {
        shownManagerIds.contains(managerId)
    }

    func markSheetShownOnAppearance(_ appearancePublisher: AnyPublisher<Void, Never>, managerId: String, onShown: @escaping () -> Void) {
        shownSheetSubscription = appearancePublisher
            .first()
            .sink { [weak self] _ in
                self?.shownManagerIds.insert(managerId)
                onShown()
            }
    }

    func markOpenedFromLink() {
        presentationSettings = MainScreenPromoSheetPresentationSettings(isOpenedFromLink: true)
    }
}

private final class StubPromoSheetManager: MainScreenPromoSheetManager {
    let id = UUID().uuidString
    let experimentKey: ExperimentFeatureFlagKey = .hardwareUpgradeStories
    var handlesPresentation = true
    var presentsSheet = true
    let state: CurrentValueSubject<MainScreenPromoSheetManagerState?, Never>
    let appearanceSubject = PassthroughSubject<Void, Never>()

    private(set) var didStart = false
    private(set) var didStop = false
    private(set) var skipReasons: [MainScreenPromoSheetSkipReason] = []
    private(set) var presentCount = 0
    private(set) var presentedOnMainThread: Bool?
    private(set) var receivedPresentationSettings: [MainScreenPromoSheetPresentationSettings] = []
    private(set) var shownCount = 0
    private(set) var requestedVariants: [String?] = []

    var isRunning: Bool {
        didStart && !didStop
    }

    init(state: MainScreenPromoSheetManagerState?) {
        self.state = CurrentValueSubject(state)
    }

    var statePublisher: AnyPublisher<MainScreenPromoSheetManagerState, Never> {
        state
            .compactMap { $0 }
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.didStart = true },
                receiveCancel: { [weak self] in self?.didStop = true }
            )
            .eraseToAnyPublisher()
    }

    func canHandlePresentation(_ settings: MainScreenPromoSheetPresentationSettings) -> Bool {
        receivedPresentationSettings.append(settings)
        return handlesPresentation
    }

    func presentSheet(experimentVariant: String?) -> AnyPublisher<Void, Never>? {
        requestedVariants.append(experimentVariant)

        guard experimentVariant != "control" else {
            return nil
        }

        presentCount += 1
        presentedOnMainThread = Thread.isMainThread
        return presentsSheet ? appearanceSubject.eraseToAnyPublisher() : nil
    }

    func logShown() {
        shownCount += 1
    }

    func logSkipped(_ reason: MainScreenPromoSheetSkipReason) {
        skipReasons.append(reason)
    }
}

private extension [StubPromoSheetManager] {
    var presentedIds: [String] {
        filter { $0.presentCount > 0 }.map(\.id)
    }
}
