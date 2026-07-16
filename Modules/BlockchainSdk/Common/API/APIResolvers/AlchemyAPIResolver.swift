//
//  AlchemyAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AlchemyAPIResolver {
    let apiKey: String

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        guard let subdomain = resolveSubdomain(for: blockchain) else {
            return nil
        }

        guard let url = URL(string: "https://\(subdomain).g.alchemy.com/v2/\(apiKey)") else {
            return nil
        }

        return NodeInfo(url: url)
    }

    private func resolveSubdomain(for blockchain: Blockchain) -> String? {
        switch blockchain {
        case .adi(let testnet):
            return testnet ? "adi-testnet" : "adi-mainnet"
        default:
            return nil
        }
    }
}
