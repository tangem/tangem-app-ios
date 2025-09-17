//
//  YieldServiceProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol YieldServiceProvider {
    var yieldSupplyProvider: YieldSupplyProvider? { get }
}

public extension YieldServiceProvider {
    var yieldSupplyProvider: YieldSupplyProvider? { nil }
}
