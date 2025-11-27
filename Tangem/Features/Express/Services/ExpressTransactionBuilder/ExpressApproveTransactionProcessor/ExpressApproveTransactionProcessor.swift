//
//  ExpressApproveTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol ExpressApproveTransactionProcessor {
    func process(data: ApproveTransactionData) async throws -> TransactionDispatcherResult
}
