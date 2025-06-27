//
//  HederaAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        guard case .hedera = blockchain else {
            return nil
        }

        let keyInfo = APIKeysInfoProvider(blockchain: blockchain, keysConfig: keysConfig).apiKeys(for: providerType)
        return .init(
            url: URL(string: "https://starter.arkhia.io/hedera/mainnet/api/v1")!,
            keyInfo: keyInfo
        )
    }
}
