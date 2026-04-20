//
//  RequiredMemoRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol RequiredMemoRestrictable {
    func validateRequiredMemo(destination: String, transactionParams: TransactionParams?) async throws
}
