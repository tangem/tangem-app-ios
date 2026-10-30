//
//  CardanoAddressUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum CardanoAddressUtils {
    static let bech32Hrp = "addr"
    static let bech32Separator = "1"

    static var bech32Prefix: String { bech32Hrp + bech32Separator }

    static func isShelleyAddress(_ address: String) -> Bool {
        address.starts(with: bech32Prefix)
    }
}
