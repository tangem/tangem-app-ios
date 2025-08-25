//
//  ENSProcessor.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Prepares data for ENS contract calls.
/// https://docs.ens.domains/resolution/names/#algorithm-1
/// https://docs.ens.domains/resolvers/universal
protocol ENSProcessor {
    func getNameHash(_ name: String) throws -> Data
    func encode(name: String) throws -> Data
}
