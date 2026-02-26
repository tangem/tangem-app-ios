//
//  ExpressRepository.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol ExpressRepository {
    func providers() async throws -> [ExpressProvider]
    func getAvailableProviders(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType) async throws -> [ExpressProvider.Id]
}

public extension ExpressRepository {
    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        try await getAvailableProviders(for: pair, rateType: .float)
    }
}
