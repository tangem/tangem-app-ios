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
import TangemLocalization
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
        #expect(outcome.failures.recorded.isEmpty)
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

    @Test("A cancelled card scan keeps the screen open without a failure")
    func cancelledScanKeepsTheScreen() async {
        let (sut, _, outcome) = makeSUT(state: Self.enableOffer, failure: PolymarketSigningError.cancelled)

        sut.handleViewAction(.authorize)
        await sut.$isProcessing.firstValue { !$0 }

        #expect(outcome.failures.recorded.isEmpty)
        #expect(outcome.closes.recorded.isEmpty)
        #expect(outcome.toasts.recorded.isEmpty)
    }

    @Test(
        "A failure before the card signs shows its toast and keeps the screen open: a wallet busy with another change says so, anything else fails the activation",
        arguments: zip(
            [URLError(.notConnectedToInternet) as Error, PolymarketSessionKeyManagerError.operationInProgress],
            [PolymarketFastTradingFailure.activationFailed, .busy]
        )
    )
    func failureBeforeSigningShowsItsToast(_ error: Error, _ shown: PolymarketFastTradingFailure) async {
        let (sut, _, outcome) = makeSUT(state: Self.enableOffer, failure: error)

        sut.handleViewAction(.authorize)
        await sut.$isProcessing.firstValue { !$0 }

        #expect(outcome.failures.recorded == [shown])
        #expect(outcome.closes.recorded.isEmpty)
        #expect(outcome.toasts.recorded.isEmpty)
    }

    @Test(
        "A key that never activated is offered as an activation, not a reactivation",
        arguments: [[PolymarketSessionSigner](), [.matching(Fixture.key(.local, status: .failed))]]
    )
    func failedKeyIsActivated(_ signers: [PolymarketSessionSigner]) {
        let (sut, _, _) = makeSUT(state: .loaded(Fixture.assess(keys: [Fixture.key(.local, status: .failed)], signers: signers)))

        #expect(sut.authorization != nil)
        #expect(sut.buttonTitle == Localization.commonActivate)
    }

    @Test("A state published while the card operation runs leaves the offer as it was")
    func stateDuringOperationIsIgnored() async throws {
        let hold = TestGate()
        let renewing = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))
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
        let failures = TestSignal<PolymarketFastTradingFailure>()
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
            showFailure: { outcome.failures.send($0) },
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
