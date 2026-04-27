//
//  KaspaAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(blockchain: Blockchain) -> NodeInfo? {
        guard
            case .kaspa = blockchain,
            let link = keysConfig.kaspaSecondaryApiUrl,
            let url = URL(string: link)
        else {
            return nil
        }

        return .init(url: url)
    }
}
