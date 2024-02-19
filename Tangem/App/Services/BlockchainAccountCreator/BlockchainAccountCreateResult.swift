//
//  BlockchainAccountCreateResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchainAccountCreateResult: Decodable {
    struct Data: Decodable {
        let accountId: String
        let walletPublicKey: String
    }

    let data: Data
}
