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

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        let link: String

        switch blockchain {
        case .bittensor:
            link = "https://api-bittensor-mainnet.dwellir.com/\(keysConfig.bittensorDwellirKey)/"
        case .azero:
            link = "https://api-aleph-zero-mainnet.n.dwellir.com/\(keysConfig.dwellirApiKey)/"
        default:
            return nil
        }

        guard let url = URL(string: link) else {
            assertionFailure("Make sure the link is valid: \(link)")
            return nil
        }

        return .init(url: url)
    }
}
