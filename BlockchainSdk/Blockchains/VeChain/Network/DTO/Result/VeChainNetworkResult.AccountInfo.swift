//
//  VeChainNetworkResult.AccountInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkResult {
    struct AccountInfo: Decodable {
        let balance: String
        let energy: String
        let hasCode: Bool
    }
}
