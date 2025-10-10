//
//  MockAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MockAPIResolver {
    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        switch providerType {
        case .mock:
            switch blockchain {
            case .cardano:
                return .init(url: URL(string: "https://wiremock.tests-d.com/cardano")!)
            case .dogecoin:
                return .init(url: URL(string: "https://wiremock.tests-d.com/dogecoin")!)
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
