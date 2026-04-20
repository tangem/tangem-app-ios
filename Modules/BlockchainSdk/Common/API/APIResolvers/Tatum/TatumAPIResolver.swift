//
//  TatumAPIResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct TatumAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        let keyInfo = APIKeysInfoProvider(blockchain: blockchain, keysConfig: keysConfig).apiKeys(for: providerType)

        switch blockchain {
        case .kusama:
            return NodeInfo(
                url: URL(string: "https://kusama-assethub.gateway.tatum.io")!,
                keyInfo: keyInfo
            )
        case .polkadot:
            return NodeInfo(
                url: URL(string: "https://polkadot-assethub.gateway.tatum.io")!,
                keyInfo: keyInfo
            )
        default:
            return nil
        }
    }
}
