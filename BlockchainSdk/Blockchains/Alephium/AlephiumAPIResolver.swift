//
//  AlephiumAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        guard case .alephium = blockchain else {
            return nil
        }

        let keysInfo = APIKeysInfoProvider(blockchain: blockchain, config: config).apiKeys(for: providerType)
        switch providerType {
        case .tangemAlephium:
            return .init(url: URL(string: "https://alephium-tangem-7c3be5.alephium.org/")!, keyInfo: keysInfo)
        default:
            return nil
        }
    }
}
