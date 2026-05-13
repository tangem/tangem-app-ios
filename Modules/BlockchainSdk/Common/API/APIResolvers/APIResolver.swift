//
//  APIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct APIResolver {
    let blockchain: Blockchain
    let keysConfig: BlockchainSdkKeysConfig

    func resolveProviders<T>(apiInfos: [NetworkProviderType], factory: (NodeInfo, NetworkProviderType?) -> T?) -> [T] {
        if blockchain.isTestnet {
            return TestnetAPINodeInfoProvider(blockchain: blockchain, keysConfig: keysConfig).urls()?.compactMap {
                factory($0, nil)
            } ?? []
        }

        let resolver = APINodeInfoResolver(blockchain: blockchain, keysConfig: keysConfig)
        return apiInfos.compactMap {
            guard let nodeInfo = resolver.resolve(for: $0) else {
                return nil
            }

            return factory(nodeInfo, $0)
        }
    }
}
