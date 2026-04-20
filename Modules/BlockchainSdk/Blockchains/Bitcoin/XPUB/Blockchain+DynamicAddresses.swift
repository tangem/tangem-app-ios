//
//  Blockchain+DynamicAddresses.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Blockchain {
    var isDynamicAddressesSupported: Bool {
        switch self {
        case .bitcoin,
             .litecoin,
             .bitcoinCash,
             .dogecoin,
             .dash,
             .ravencoin:
            return true
        default:
            return false
        }
    }
}
