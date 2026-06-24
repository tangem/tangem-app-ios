//
//  StakingTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

protocol StakingTransactionSender: StakingModelStateProvider, SendSummaryInput, SendBaseOutput {
    var target: StakingTargetInfo? { get }

    func send(_ transaction: StakingTransactionAction) async throws -> TransactionDispatcherResult
}
