//
//  NowNodesAPIKeysInfoProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct NowNodesAPIKeysInfoProvider {
    let apiKey: String
    func apiKeys(for blockchain: Blockchain) -> APIHeaderKeyInfo? {
        switch blockchain {
        case .xrp, .tron, .algorand, .aptos, .solana, .odysseyChain, .sonic:
            return .init(
                headerName: Constants.nowNodesApiKeyHeaderName,
                headerValue: apiKey
            )
        default: return nil
        }
    }
}
