//
//  InformationRelevanceServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem

@Suite("Information relevance service")
struct InformationRelevanceServiceTests {
    @Test(
        "A fee that is still loading or not actual is skipped, and the next actual fee settles the check",
        arguments: [
            (Decimal?.none, true),
            (Decimal(2), false),
        ]
    )
    func skippedFeeDoesNotSettleCheck(skippedFeeValue: Decimal?, isSkippedFeeActual: Bool) {
        let (sut, input, updater) = makeSUT(oldFeeValue: 1)
        let results = record(sut.updateInformation())

        input.isSelectedFeeActual = isSkippedFeeActual
        input.emit(TokenFeeFixture.make(value: skippedFeeValue))
        #expect(results.values.isEmpty)

        input.isSelectedFeeActual = true
        input.emit(TokenFeeFixture.make(value: 2))
        #expect(results.values == [.feeWasIncreased])
        #expect(updater.updateFeesCallCount == 1)
    }

    @Test(
        "A loaded fee is compared with the one the check started from",
        arguments: [
            (Decimal(2), InformationRelevanceServiceUpdateResult.feeWasIncreased),
            (Decimal(1), .ok),
            (Decimal(0.5), .ok),
        ]
    )
    func loadedFeeIsCompared(newValue: Decimal, expected: InformationRelevanceServiceUpdateResult) {
        let (sut, input, _) = makeSUT(oldFeeValue: 1)
        let results = record(sut.updateInformation())

        input.emit(TokenFeeFixture.make(value: newValue))

        #expect(results.values == [expected])
    }
}

// MARK: - Helpers

private extension InformationRelevanceServiceTests {
    func makeSUT(oldFeeValue: Decimal) -> (CommonInformationRelevanceService, SendFeeInputStub, SendFeeUpdaterSpy) {
        let input = SendFeeInputStub(selectedFee: TokenFeeFixture.make(value: oldFeeValue))
        let updater = SendFeeUpdaterSpy()
        let sut = CommonInformationRelevanceService(input: input, provider: updater)
        return (sut, input, updater)
    }

    func record(
        _ publisher: AnyPublisher<InformationRelevanceServiceUpdateResult, Error>
    ) -> PublisherRecorder<InformationRelevanceServiceUpdateResult> {
        PublisherRecorder(publisher.catch { _ in Empty() }.eraseToAnyPublisher())
    }
}

// MARK: - Stubs

private final class SendFeeInputStub: SendFeeInput {
    private let selectedFeeSubject: CurrentValueSubject<TokenFee, Never>

    var isSelectedFeeActual = true

    init(selectedFee: TokenFee) {
        selectedFeeSubject = CurrentValueSubject(selectedFee)
    }

    var selectedFee: TokenFee? { selectedFeeSubject.value }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { selectedFeeSubject.eraseToAnyPublisher() }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    func emit(_ fee: TokenFee) {
        selectedFeeSubject.send(fee)
    }
}

private final class SendFeeUpdaterSpy: SendFeeUpdater {
    private(set) var updateFeesCallCount = 0

    func updateFees() {
        updateFeesCallCount += 1
    }
}
