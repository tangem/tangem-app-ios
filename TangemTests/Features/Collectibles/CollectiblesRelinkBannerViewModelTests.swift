//
//  CollectiblesRelinkBannerViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemCollectibles
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesRelinkBannerViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesRelinkBannerViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesRelinkBannerViewModel

    @Test("A failed relink shows the error")
    func failureShowsError() async {
        let relinker = RelinkerStub(errors: [RelinkError()])
        let sut = makeSUT(relinker: relinker)
        let errors = ErrorRecorder(sut: sut, relinker: relinker)

        sut.relink()
        await waitUntil { errors.onboardCalls.isNotEmpty }

        #expect(errors.onboardCalls == [1])
    }

    @Test("A cancelled card tap shows no error, unlike a failure right after it")
    func cancellationIsSilent() async {
        let relinker = RelinkerStub(errors: [CancellationError(), RelinkError()])
        let sut = makeSUT(relinker: relinker)
        let errors = ErrorRecorder(sut: sut, relinker: relinker)

        sut.relink()
        await waitUntil { relinker.onboardCallsCount == 1 }
        sut.relink()
        await waitUntil { errors.onboardCalls.isNotEmpty }

        #expect(errors.onboardCalls == [2])
    }

    @Test("A wallet that confirms by holding opens the reconnection screen instead of signing right away")
    func holdToConfirmOpensReconnection() {
        let relinker = RelinkerStub(errors: [])
        var openedCount = 0
        let sut = makeSUT(relinker: relinker) { openedCount += 1 }

        sut.relink()

        #expect(openedCount == 1)
        #expect(relinker.onboardCallsCount == 0)
    }
}

// MARK: - Helpers

private extension CollectiblesRelinkBannerViewModelTests {
    func makeSUT(relinker: RelinkerStub, openReconnection: (@MainActor () -> Void)? = nil) -> SUT {
        let sut = SUT(relinker: relinker, openReconnection: openReconnection)
        return trackForMemoryLeaks(sut)
    }
}

// MARK: - Doubles

private struct RelinkError: Error {}

private final class RelinkerStub: CollectiblesRelinkStatusProvider, CollectiblesOnboarder {
    private let state: OSAllocatedUnfairLock<State>

    var onboardCallsCount: Int {
        state.withLock(\.callsCount)
    }

    var isRelinkRequiredPublisher: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    var isRelinkingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    init(errors: [any Error]) {
        state = OSAllocatedUnfairLock(initialState: State(errors: errors))
    }

    func onboard() async throws {
        let error = state.withLock { state -> (any Error)? in
            state.callsCount += 1
            return state.errors.isEmpty ? nil : state.errors.removeFirst()
        }

        guard let error else {
            return
        }

        throw error
    }

    private struct State {
        var errors: [any Error]
        var callsCount = 0
    }
}

@MainActor
private final class ErrorRecorder {
    private(set) var onboardCalls: [Int] = []

    private var subscription: AnyCancellable?

    init(sut: CollectiblesRelinkBannerViewModel, relinker: RelinkerStub) {
        subscription = sut.$errorMessage
            .compactMap { $0 }
            .sink { [weak self, relinker] _ in
                self?.onboardCalls.append(relinker.onboardCallsCount)
            }
    }
}
