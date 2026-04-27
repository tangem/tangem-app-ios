//
//  QuickNodeAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct QuickNodeAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        guard let credentials = resolveCredentials(for: blockchain) else {
            return nil
        }

        guard let url = URL(string: "https://\(credentials.subdomain)/\(credentials.apiKey)") else {
            return nil
        }

        return NodeInfo(url: url)
    }

    private func resolveCredentials(for blockchain: Blockchain) -> BlockchainSdkKeysConfig.QuickNodeCredentials? {
        switch blockchain {
        case .bsc:
            return keysConfig.quickNodeBscCredentials
        case .solana:
            return keysConfig.quickNodeSolanaCredentials
        case .plasma:
            return keysConfig.quickNodePlasmaCredentials
        case .monad:
            return keysConfig.quickNodeMonadCredentials
        default:
            return nil
        }
    }
}
