//
//  BlockchainAccountCreateParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchainAccountCreateParameters: Encodable {
    let networkId: String
    let walletPublicKey: String
}
