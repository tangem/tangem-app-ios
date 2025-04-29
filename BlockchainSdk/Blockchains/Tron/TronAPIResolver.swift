//
//  TronAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct TronAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(blockchain: Blockchain) -> NodeInfo? {
        guard case .tron = blockchain else {
            return nil
        }

        return .init(
            url: URL(string: "https://api.trongrid.io")!,
            keyInfo: APIKeysInfoProvider(blockchain: blockchain, keysConfig: keysConfig).apiKeys(for: .tron)
        )
    }
}
