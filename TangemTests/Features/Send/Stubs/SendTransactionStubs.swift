//
//  SendTransactionStubs.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemStaking
@testable import Tangem

/// Collects the transactions a send flow actually handed to the dispatcher, so a test can assert what was
/// signed rather than what the model believed it would sign.
final class TransactionRecorder: @unchecked Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [BSDKTransaction]())

    var dispatchedTransactions: [BSDKTransaction] { state.withLock { $0 } }

    func record(_ transaction: BSDKTransaction) {
        state.withLock { $0.append(transaction) }
    }
}

struct RecordingTransactionDispatcher: TransactionDispatcher {
    let recorder: TransactionRecorder
    var error: Error?
    var entered: TestGate?
    var release: TestGate?

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        if case .transfer(let bsdkTransaction) = transaction {
            recorder.record(bsdkTransaction)
        }

        entered?.open()
        await release?.wait()

        if let error {
            throw error
        }

        return TransactionDispatcherResult(hash: "hash", url: nil, signerType: "test", currentHost: "test")
    }
}

struct RecordingTransactionDispatcherProvider: TransactionDispatcherProvider {
    let recorder: TransactionRecorder
    var error: Error?
    var entered: TestGate?
    var release: TestGate?

    func makeTransferTransactionDispatcher() -> TransactionDispatcher {
        RecordingTransactionDispatcher(recorder: recorder, error: error, entered: entered, release: release)
    }

    func makeApproveTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeCEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher { TransactionDispatcherStub() }
}

final class InformationRelevanceServiceStub: InformationRelevanceService {
    let isActual: Bool
    private let updateResult: InformationRelevanceServiceUpdateResult

    init(isActual: Bool = true, updateResult: InformationRelevanceServiceUpdateResult = .ok) {
        self.isActual = isActual
        self.updateResult = updateResult
    }

    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, Error> {
        Just(updateResult).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

struct SendManagementModelAnalyticsLoggerStub: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError) {}
    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    ) {}
}
