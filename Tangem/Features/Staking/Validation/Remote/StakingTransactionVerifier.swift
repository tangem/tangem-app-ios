//
//  StakingTransactionVerifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol StakingTransactionVerifier {
    func verify(
        network: RemoteValidationNetwork,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws
}

enum RemoteValidationNetwork {
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
