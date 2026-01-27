//
//  MockAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MockAPIResolver {
    private static let baseURL = "https://wiremock.tests-d.com"

    private static func urlString(for blockchain: Blockchain) -> String? {
        switch blockchain {
        case .bitcoin:
            return "\(baseURL)/bitcoin"
        case .chia:
            return "\(baseURL)/chia"
        case .cardano:
            return "\(baseURL)/cardano"
        case .dogecoin:
            return "\(baseURL)/dogecoin"
        case .solana:
            return "\(baseURL)/solana"
        default:
            return nil
        }
    }

    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        guard case .mock = providerType else {
            return nil
        }

        guard let urlString = Self.urlString(for: blockchain),
              let url = URL(string: urlString) else {
            return nil
        }

        return .init(url: url)
    }
}
