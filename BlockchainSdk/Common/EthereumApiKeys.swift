//
//  EthereumApiKeys.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumApiKeys {
    let infuraProjectId: String
    let nowNodesApiKey: String
    let getBlockApiKeys: [Blockchain: String]
    let quickNodeBscCredentials: BlockchainSdkConfig.QuickNodeCredentials
}
