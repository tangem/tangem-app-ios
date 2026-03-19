//
//  ApproveOutputMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

@testable import Tangem

final class ApproveOutputMock: ApproveOutput {
    private(set) var approveDidSendTransactionCallCount: Int = 0

    func approveDidSendTransaction() {
        approveDidSendTransactionCallCount += 1
    }
}
