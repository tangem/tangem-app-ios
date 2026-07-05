//
//  DerivationPath+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public extension DerivationPath {
    func dropLastNode(count: Int) -> DerivationPath {
        return DerivationPath(nodes: nodes.dropLast(count))
    }
}
