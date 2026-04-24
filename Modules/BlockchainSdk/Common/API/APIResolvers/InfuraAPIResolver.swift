//
//  InfuraAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct InfuraAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        switch blockchain {
        case .ethereum:
            return .init(url: URL(string: "https://mainnet.infura.io/v3/\(keysConfig.infuraProjectId)")!)
        case .arbitrum:
            return .init(url: URL(string: "https://arbitrum-mainnet.infura.io/v3/\(keysConfig.infuraProjectId)")!)
        default:
            return nil
        }
    }
}
