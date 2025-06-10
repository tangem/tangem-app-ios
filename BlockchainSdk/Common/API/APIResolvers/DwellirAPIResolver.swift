//
//  DwellirAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DwellirAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve() -> NodeInfo? {
        guard let url = URL(string: "https://api-bittensor-mainnet.dwellir.com/\(keysConfig.bittensorDwellirKey)/") else {
            return nil
        }

        return .init(url: url)
    }
}
