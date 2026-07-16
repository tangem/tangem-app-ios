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
    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws
    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider]
    func getAvailableProvidersIds(
        for pair: ExpressManagerSwappingPair,
        rateType: ExpressProviderRateType?
    ) async -> [ExpressProvider.Id]
}
