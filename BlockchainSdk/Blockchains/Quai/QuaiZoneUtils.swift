//
//  QuaiZoneUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/**
 * A zone is the lowest level shard within the Quai network hierarchy. Zones are the only shards in the network that
 * accept user transactions. The value is a hexadecimal string representing the encoded value of the zone. Read more
 * [here](https://github.com/quai-network/qips/blob/master/qip-0002.md).
 *
 * @category Constants
 */
enum QuaiZoneType: String, CaseIterable {
    case cyprus1 = "0x00"

    // MARK: - Constants

    var cyprus1FirstByte: UInt8 {
        switch self {
        case .cyprus1:
            return 0x00
        }
    }

    var cyprus1NinthBitMask: UInt8 {
        switch self {
        case .cyprus1:
            return 0x80
        }
    }
}
