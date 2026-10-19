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

    private func withProvider(
        managerStates: [MainScreenPromoSheetManagerState?],
        _ operation: (MainScreenPromoSheetProvider, [StubPromoSheetManager], StubPromoSheetInteractor) async -> Void
    ) async {
        let interactor = StubPromoSheetInteractor()
        let managers = managerStates.map { StubPromoSheetManager(state: $0) }
        let provider = makeProvider(managers: managers, interactor: interactor)

        await operation(provider, managers, interactor)
    }

    private func makeProvider(
        managers: [StubPromoSheetManager],
        interactor: StubPromoSheetInteractor = StubPromoSheetInteractor()
    ) -> MainScreenPromoSheetProvider {
        MainScreenPromoSheetProvider(managers: managers, interactor: interactor)
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }
}

// MARK: - Stubs

private final class StubPromoSheetInteractor: MainScreenPromoSheetInteractor {
    private(set) var presentationSettings = MainScreenPromoSheetPresentationSettings(isOpenedFromLink: false)
    var didClaimFirstAppearance = false

    func initialize() {}

    func claimFirstMainScreenAppearance() -> Bool {
        guard !didClaimFirstAppearance else {
            return false
        }

        didClaimFirstAppearance = true
        return true
    }

    func markOpenedFromLink() {
        presentationSettings = MainScreenPromoSheetPresentationSettings(isOpenedFromLink: true)
    }
}

private final class StubPromoSheetManager: MainScreenPromoSheetManager {
    let id = UUID().uuidString
    var handlesPresentation = true
    let state: CurrentValueSubject<MainScreenPromoSheetManagerState?, Never>

    private(set) var didStart = false
    private(set) var didStop = false
    private(set) var skipReasons: [MainScreenPromoSheetSkipReason] = []
    private(set) var presentCount = 0
    private(set) var presentedOnMainThread: Bool?
    private(set) var receivedPresentationSettings: [MainScreenPromoSheetPresentationSettings] = []

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

    func presentSheet() {
        presentCount += 1
        presentedOnMainThread = Thread.isMainThread
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
