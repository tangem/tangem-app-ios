//
//  ApproveCoordinatingMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

@testable import Tangem

final class ApproveCoordinatingMock: ApproveCoordinating {
    private(set) var didSendApproveTransactionCallCount: Int = 0
    private(set) var userDidCancelCallCount: Int = 0
    private(set) var openLearnMoreCallCount: Int = 0
    private(set) var openFeeTokenSelectionCallCount: Int = 0

    func didSendApproveTransaction() {
        didSendApproveTransactionCallCount += 1
    }

    func userDidCancel() {
        userDidCancelCallCount += 1
    }

    func openLearnMore() {
        openLearnMoreCallCount += 1
    }

    func openFeeTokenSelection() {
        openFeeTokenSelectionCallCount += 1
    }
}
