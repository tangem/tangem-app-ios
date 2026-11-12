//
//  PolymarketFastTradingActivationViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket fast trading activation screen", .timeLimit(.minutes(1)))
struct PolymarketFastTradingActivationViewModelTests {
    @Test("Authorizing signs the offer the screen shows")
    func authorizeSignsTheShownOffer() async throws {
        let previous = Fixture.key(.previous)
        let (sut, service, outcome) = makeSUT(state: .loaded(Fixture.assess(keys: [previous], signers: [.matching(previous)])))

        sut.handleViewAction(.authorize)
        try await outcome.closes.next()

        #expect(service.authorizations == [.replace(previous: previous, revokesPrevious: true)])
    }

    @Test("A finished operation shows its progress and closes the screen once")
    func finishedOperationClosesOnce() async throws {
        let (sut, _, outcome) = makeSUT(state: Self.enableOffer)

        sut.handleViewAction(.authorize)
        try await outcome.closes.next()

        #expect(outcome.closes.recorded.count == 1)
        #expect(outcome.toasts.recorded == [PolymarketFastTradingStrings.activationInProgress])
        #expect(sut.alert == nil)
    }

    @Test("A second tap while the card operation runs doesn't start another one")
    func secondTapIsIgnored() async throws {
        let hold = TestGate()
        let (sut, service, outcome) = makeSUT(state: Self.enableOffer, hold: hold)

        sut.handleViewAction(.authorize)
        try await service.entered.next()
        sut.handleViewAction(.authorize)
        hold.open()
        try await outcome.closes.next()

        #expect(service.authorizations == [.enable])
    }

    @Test("A cancelled card scan keeps the screen open without an alert")
    func cancelledScanKeepsTheScreen() async {
        let (sut, _, outcome) = makeSUT(state: Self.enableOffer, failure: PolymarketSigningError.cancelled)

        sut.handleViewAction(.authorize)
        await sut.$isProcessing.firstValue { !$0 }

        #expect(sut.alert == nil)
        #expect(outcome.closes.recorded.isEmpty)
        #expect(outcome.toasts.recorded.isEmpty)
    }

    @Test("A failed operation shows an alert and keeps the screen open")
    func failureShowsAnAlert() async {
        let (sut, _, outcome) = makeSUT(state: Self.enableOffer, failure: PolymarketSessionKeyManagerError.operationInProgress)

        sut.handleViewAction(.authorize)
        await sut.$isProcessing.firstValue { !$0 }

        #expect(sut.alert != nil)
        #expect(outcome.closes.recorded.isEmpty)
        #expect(outcome.toasts.recorded.isEmpty)
    }

    @Test("A state published while the card operation runs leaves the offer as it was")
    func stateDuringOperationIsIgnored() async throws {
        let hold = TestGate()
        let renewing = Fixture.key(.local, renewAfter: Fixture.now.addingTimeInterval(-1))
        let (sut, service, outcome) = makeSUT(state: .loaded(Fixture.assess(keys: [renewing], signers: [.matching(renewing)])), hold: hold)

        sut.handleViewAction(.authorize)
        try await service.entered.next()
        service.publish(.loading)

        #expect(sut.authorization == .renew)

        hold.open()
        try await outcome.closes.next()
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketFastTradingActivationViewModelTests {
    static let enableOffer = PolymarketFastTradingState.loaded(Fixture.assess(keys: []))

    struct Outcome {
        let closes = TestSignal<Void>()
        let toasts = TestSignal<String>()
    }

    func makeSUT(
        state: PolymarketFastTradingState,
        hold: TestGate? = nil,
        failure: Error? = nil
    ) -> (sut: PolymarketFastTradingActivationViewModel, service: FastTradingServiceSpy, outcome: Outcome) {
        let service = FastTradingServiceSpy(state: state, hold: hold, failure: failure)
        let outcome = Outcome()
        let sut = PolymarketFastTradingActivationViewModel(
            service: service,
            signingButtonType: .requiredNFCInteraction,
            showProgress: { outcome.toasts.send($0) },
            onClose: { outcome.closes.send() }
        )

        return (sut, service, outcome)
    }
}

// MARK: - Stubs

@MainActor
private final class FastTradingServiceSpy: PolymarketFastTradingOperating {
    let entered = TestSignal<Void>()
    private(set) var authorizations: [PolymarketFastTradingAuthorization] = []

    private let stateSubject: CurrentValueSubject<PolymarketFastTradingState, Never>
    private let hold: TestGate?
    private let failure: Error?

    init(state: PolymarketFastTradingState, hold: TestGate?, failure: Error?) {
        stateSubject = CurrentValueSubject(state)
        self.hold = hold
        self.failure = failure
    }

    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var state: PolymarketFastTradingState {
        stateSubject.value
    }

    func publish(_ state: PolymarketFastTradingState) {
        stateSubject.send(state)
    }

    func refresh() async {}

    func authorize(_ authorization: PolymarketFastTradingAuthorization) async throws {
        authorizations.append(authorization)
        entered.send()

        await hold?.wait()

        if let failure {
            throw failure
        }
    }

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws {
        Issue.record("The activation screen authorizes a presigned batch")
    }

    func revoke(sessionKeyAddress: String) async throws {
        Issue.record("The activation screen revokes a session key")
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws {
        Issue.record("The activation screen toggles a session key")
    }
}
