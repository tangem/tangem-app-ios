//
//  Card+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk
import CryptoKit

extension CardDTO {
    var walletSignedHashes: Int {
        wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }

    var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }
}
