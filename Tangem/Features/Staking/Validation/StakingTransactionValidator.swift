//
//  StakingTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol StakingTransactionValidator {
    func validate(_ unsignedTransactions: [String]) async throws
}
