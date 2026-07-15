//
//  StakingValidationComposer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Runs local and remote staking validators in sequence.
struct StakingValidationComposer: StakingTransactionValidator {
    private let localValidator, remoteValidator: StakingTransactionValidator?

    init(localValidator: StakingTransactionValidator?, remoteValidator: StakingTransactionValidator?) {
        self.localValidator = localValidator
        self.remoteValidator = remoteValidator
    }

    func validate(_ unsignedTransactions: [String]) async throws {
        try await localValidator?.validate(unsignedTransactions)
        try await remoteValidator?.validate(unsignedTransactions)
    }
}
