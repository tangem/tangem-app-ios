//
//  PolymarketWithdrawServiceSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketWithdrawServiceSpy: PolymarketWithdrawService {
    typealias Answer = Result<PolymarketWithdrawRecord, PolymarketWithdrawError>

    var submitted: [PolymarketRelayedBatch] { state.withLock { $0.submitted } }
    var recordRequests: Int { state.withLock { $0.recordRequests } }

    var onRecordRequest: @Sendable (Int) -> Void {
        get { hook.withLock { $0 } }
        set { hook.withLock { $0 = newValue } }
    }

    private let state: OSAllocatedUnfairLock<State>
    private let hook: OSAllocatedUnfairLock<@Sendable (Int) -> Void>
    private let transactionId: String

    init(
        submitResults: [Answer?] = [],
        recordAnswers: [Answer] = [],
        transactionId: String = "tx-1",
        onRecordRequest: @escaping @Sendable (Int) -> Void = { _ in }
    ) {
        state = OSAllocatedUnfairLock(initialState: State(submitResults: submitResults, recordAnswers: recordAnswers))
        self.transactionId = transactionId
        hook = OSAllocatedUnfairLock(initialState: onRecordRequest)
    }

    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        let answer = state.withLock { state -> Answer? in
            state.submitted.append(batch)

            return state.submitResults.isEmpty ? nil : state.submitResults.removeFirst()
        }

        return try unwrap(answer)
    }

    func record(ofWithdrawal transactionId: String) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        let (ordinal, answer) = state.withLock { state -> (Int, Answer?) in
            state.recordRequests += 1

            let answer = state.recordAnswers.count > 1 ? state.recordAnswers.removeFirst() : state.recordAnswers.first

            return (state.recordRequests, answer)
        }

        onRecordRequest(ordinal)

        return try unwrap(answer)
    }

    private func unwrap(_ answer: Answer?) throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        switch answer {
        case .none: return PolymarketWithdrawRecord(transactionId: transactionId, state: .inProgress, transactionHash: nil)
        case .success(let record): return record
        case .failure(let error): throw error
        }
    }

    private struct State {
        var submitted: [PolymarketRelayedBatch] = []
        var recordRequests = 0
        var submitResults: [Answer?]
        var recordAnswers: [Answer]
    }
}
