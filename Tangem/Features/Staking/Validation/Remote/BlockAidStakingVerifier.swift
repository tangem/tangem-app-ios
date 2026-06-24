//
//  BlockAidStakingVerifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Verifies staking transactions via BlockAid API.
protocol BlockAidStakingVerifier {
    func verify(
        network: BlockAidSupportedNetwork,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws
}

enum BlockAidSupportedNetwork {
    case evm(Blockchain)
    case solana

    init?(blockchain: Blockchain) {
        switch blockchain {
        case .bsc, .ethereum:
            self = .evm(blockchain)
        case .solana:
            self = .solana
        default:
            return nil
        }
    }
}
