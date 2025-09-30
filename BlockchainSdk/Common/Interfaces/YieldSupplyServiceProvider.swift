//
//  YieldServiceProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol YieldSupplyServiceProvider {
    var yieldSupplyService: YieldSupplyService? { get }
}

public extension YieldSupplyServiceProvider {
    var yieldSupplyService: YieldSupplyService? { nil }
}
