//
//  TransactionDispatcherMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Foundation
@testable import Tangem

final class TransactionDispatcherMock: TransactionDispatcher {
    // MARK: - Stubs

    var sendResult: Result<TransactionDispatcherResult, Error> = .success(
        TransactionDispatcherResult(hash: "0xmockhash", url: nil, signerType: "mock", currentHost: "mock.host")
    )
    var hasNFCInteraction: Bool = false

    // MARK: - Call tracking

    private(set) var sendCalls: [TransactionDispatcherTransactionType] = []

    // MARK: - TransactionDispatcher

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        sendCalls.append(transaction)
        return try sendResult.get()
    }
}
