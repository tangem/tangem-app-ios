//
//  CardanoAddressType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum CardanoAddressType: String {
    case bech32, legacy
    
    var localizedName: String {
        switch self {
        case .bech32: return "Default"
        case .legacy: return "Legacy"
        }
    }
}
