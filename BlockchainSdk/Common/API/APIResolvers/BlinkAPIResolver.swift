//
//  BlinkAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// Ethereum - https://eth.blinklabs.xyz/v1/***
// Base     - https://base.blinklabs.xyz/v1/***
// BSC      - https://bsc.blinklabs.xyz/v1/***
// Solana   - https://sol.blinklabs.xyz/v1/***
// Arbitrum - https://arb.blinklabs.xyz/v1/***

struct BlinkAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        guard let subdomain = resolveSubdomain(for: blockchain) else {
            return nil
        }

        guard let url = URL(string: "https://\(subdomain).blinklabs.xyz/v1/\(keysConfig.blinkApiKey)") else {
            return nil
        }

        return NodeInfo(url: url)
    }

    private func resolveSubdomain(for blockchain: Blockchain) -> String? {
        switch blockchain {
        case .ethereum:
            return "eth"
        case .base:
            return "base"
        case .bsc:
            return "bsc"
        case .solana:
            return "sol"
        case .arbitrum:
            return "arb"
        default:
            return nil
        }
    }
}
