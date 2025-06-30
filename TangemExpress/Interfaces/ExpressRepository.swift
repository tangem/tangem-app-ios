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
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency]) async throws
    func updatePairs(for wallet: ExpressWalletCurrency) async throws

    func providers() async throws -> [ExpressProvider]
    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id]

    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair]
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair]
}
