//
//  YieldService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol YieldService {
    func getYieldMarkets() async throws -> [String]
}

public struct CommonYieldService: YieldService {
    public func getYieldMarkets() async throws -> [String] {
        #warning("Implement getYieldMarkets")
        fatalError("Unimplemented")
    }
}
