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
    case cyprus2 = "0x01"
    case cyprus3 = "0x02"
    case paxos1 = "0x10"
    case paxos2 = "0x11"
    case paxos3 = "0x12"
    case hydra1 = "0x20"
    case hydra2 = "0x21"
    case hydra3 = "0x22"
}
