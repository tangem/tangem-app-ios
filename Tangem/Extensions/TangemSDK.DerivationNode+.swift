//
//  TangemSDK.DerivationNode+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension DerivationNode {
    var rawIndex: UInt32 {
        switch self {
        case .hardened(let index):
            return index
        case .nonHardened(let index):
            return index
        }
    }
}
