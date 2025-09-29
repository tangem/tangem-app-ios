//
//  YieldServiceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol YieldServiceProvider {
    var yieldService: YieldTokenService? { get }
}

public extension YieldServiceProvider {
    var yieldService: YieldTokenService? { nil }
}
