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
        case .polygon, .bsc:
            self = .evm(blockchain)
        case .solana:
            self = .solana
        default:
            return nil
        }
    }
}

enum LocalStakingSupportedNetwork {
    case tron
    case solana
    case cosmos
    case polygon
    case bsc
    case cardano

    init?(blockchain: Blockchain) {
        switch blockchain {
        case .tron: self = .tron
        case .solana: self = .solana
        case .cosmos: self = .cosmos
        case .polygon: self = .polygon
        case .bsc: self = .bsc
        case .cardano: self = .cardano
        default: return nil
        }
    }
}
