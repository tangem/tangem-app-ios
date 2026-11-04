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
        await waitUntil { errors.relinkCalls.isNotEmpty }

        #expect(errors.relinkCalls == [1])
    }

    @Test("A cancelled card tap shows no error, unlike a failure right after it")
    func cancellationIsSilent() async {
        let relinker = RelinkerStub(errors: [CancellationError(), RelinkError()])
        let sut = makeSUT(relinker: relinker)
        let errors = ErrorRecorder(sut: sut, relinker: relinker)

        sut.relink()
        await waitUntil { relinker.relinkCallsCount == 1 }
        sut.relink()
        await waitUntil { errors.relinkCalls.isNotEmpty }

        #expect(errors.relinkCalls == [2])
    }

    @Test("A wallet that confirms by holding opens the reconnection screen instead of signing right away")
    func holdToConfirmOpensReconnection() {
        let relinker = RelinkerStub(errors: [])
        var openedCount = 0
        let sut = makeSUT(relinker: relinker, openReconnection: { openedCount += 1 })

        sut.relink()

        #expect(openedCount == 1)
        #expect(relinker.relinkCallsCount == 0)
    }

    @Test("A relink that finds no account closes Packs")
    func missingAccountClosesPacks() async {
        let relinker = RelinkerStub(errors: [], outcome: .accountNotFound)
        let (closings, closing) = AsyncStream.makeStream(of: Void.self)
        let sut = makeSUT(relinker: relinker, closeCollectibles: { closing.yield() })

        sut.relink()
        var closingsIterator = closings.makeAsyncIterator()
        await closingsIterator.next()

        #expect(relinker.relinkCallsCount == 1)
        #expect(sut.errorMessage == nil)
    }

    @Test("A relink that finds the account keeps Packs open")
    func relinkedKeepsPacksOpen() async throws {
        let relinker = RelinkerStub(errors: [])
        var closingsCount = 0
        let sut = makeSUT(relinker: relinker, closeCollectibles: { closingsCount += 1 })

        sut.relink()
        let relinkTask = try #require(sut.relinkTask)
        await relinkTask.value

        #expect(relinker.relinkCallsCount == 1)
        #expect(closingsCount == 0)
    }
}

// MARK: - Helpers

private extension CollectiblesRelinkBannerViewModelTests {
    func makeSUT(
        relinker: RelinkerStub,
        closeCollectibles: @escaping @MainActor () -> Void = {},
        openReconnection: (@MainActor () -> Void)? = nil
    ) -> SUT {
        let sut = SUT(relinker: relinker, openReconnection: openReconnection, closeCollectibles: closeCollectibles)
        return trackForMemoryLeaks(sut)
    }
}

// MARK: - Doubles

private struct RelinkError: Error {}

private final class RelinkerStub: CollectiblesRelinkStatusProvider, CollectiblesRelinker {
    private let state: OSAllocatedUnfairLock<State>
    private let outcome: CollectiblesRelinkOutcome

    var relinkCallsCount: Int {
        state.withLock(\.callsCount)
    }

    var isRelinkRequiredPublisher: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    var isRelinkingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    init(errors: [any Error], outcome: CollectiblesRelinkOutcome = .relinked) {
        state = OSAllocatedUnfairLock(initialState: State(errors: errors))
        self.outcome = outcome
    }

    func refreshStateSilently() async {}

    func relink() async throws -> CollectiblesRelinkOutcome {
        let error = state.withLock { state -> (any Error)? in
            state.callsCount += 1
            return state.errors.isEmpty ? nil : state.errors.removeFirst()
        }

        guard let error else {
            return outcome
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
    private(set) var relinkCalls: [Int] = []

    private var subscription: AnyCancellable?

    init(sut: CollectiblesRelinkBannerViewModel, relinker: RelinkerStub) {
        subscription = sut.$errorMessage
            .compactMap { $0 }
            .sink { [weak self, relinker] _ in
                self?.relinkCalls.append(relinker.relinkCallsCount)
            }
    }
}
