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
    let hasNFCInteraction = false

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        if case .transfer(let bsdkTransaction) = transaction {
            recorder.record(bsdkTransaction)
        }

        return TransactionDispatcherResult(hash: "hash", url: nil, signerType: "test", currentHost: "test")
    }
}

struct RecordingTransactionDispatcherProvider: TransactionDispatcherProvider {
    let recorder: TransactionRecorder

    func makeTransferTransactionDispatcher() -> TransactionDispatcher { RecordingTransactionDispatcher(recorder: recorder) }
    func makeApproveTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeCEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
}

final class InformationRelevanceServiceStub: InformationRelevanceService {
    var isActual: Bool { true }
    func informationDidUpdated() {}
    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, Error> {
        Just(.ok).setFailureType(to: Error.self).eraseToAnyPublisher()
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
