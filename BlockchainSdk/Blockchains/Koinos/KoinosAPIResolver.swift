//
//  KoinosAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct KoinosAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(blockchain: Blockchain) -> NodeInfo? {
        guard case .koinos = blockchain else {
            return nil
        }

        return .init(
            url: URL(string: "https://api.koinos.pro/jsonrpc")!,
            keyInfo: APIKeysInfoProvider(blockchain: blockchain, keysConfig: keysConfig).apiKeys(for: .koinosPro)
        )
    }
}
