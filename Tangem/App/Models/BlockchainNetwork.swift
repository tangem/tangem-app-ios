//
//  BlockchainNetwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct TangemSdk.DerivationPath

struct BlockchainNetwork: Codable, Hashable, Equatable {
    let blockchain: Blockchain
    let derivationPath: DerivationPath?

    // [REDACTED_TODO_COMMENT]
    init(_ blockchain: Blockchain, derivationPath: DerivationPath? = nil) {
        self.blockchain = blockchain
        self.derivationPath = derivationPath
    }
}
