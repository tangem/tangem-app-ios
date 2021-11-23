//
//  CardType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
#endif

enum TangemNote: String, CaseIterable {
    /// AB01
    case btc = "AB01"
    /// AB02
    case eth = "AB02"
    /// AB03
    case ada = "AB03"
    /// AB04
    case dogecoin = "AB04"
    /// AB05
    case bnb = "AB05"
    /// AB06
    case xrp = "AB06"
    
    static func isNoteBatch(_ batch: String) -> Bool {
        TangemNote(rawValue: batch.uppercased()) != nil
    }
}
