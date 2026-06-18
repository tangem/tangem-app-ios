//
//  LocalStakingTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Routes to blockchain-specific validators based on network type.
struct LocalStakingTransactionValidator: StakingTransactionValidator {
    private let network: LocalStakingSupportedNetwork

    init(network: LocalStakingSupportedNetwork) {
        self.network = network
    }

    func validate(_ unsignedTransactions: [String]) async throws {
        for unsignedData in unsignedTransactions {
            try validateTransaction(unsignedData: unsignedData)
        }
    }

    private func validateTransaction(unsignedData: String) throws {
        switch network {
        case .tron:
            try TronStakingTransactionValidator.validate(unsignedData)
        case .solana:
            try SolanaStakingTransactionValidator.validate(unsignedData)
        case .cosmos:
            try CosmosStakingTransactionValidator.validate(unsignedData)
        case .polygon:
            try PolygonStakingTransactionValidator.validate(unsignedData)
        case .bsc:
            try BNBStakingTransactionValidator.validate(unsignedData)
        case .cardano:
            try CardanoStakingTransactionValidator.validate(unsignedData)
        }
    }
}
