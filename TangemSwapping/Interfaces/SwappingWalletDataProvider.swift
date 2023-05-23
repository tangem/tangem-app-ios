//
//  SwappingWalletDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol SwappingWalletDataProvider {
    func getWalletAddress(currency: Currency) -> String?

    func getGasOptions(
        blockchain: SwappingBlockchain,
        value: Decimal,
        data: Data,
        destinationAddress: String
    ) async throws -> [EthereumGasDataModel]

    func getBalance(for currency: Currency) async throws -> Decimal
    func getBalance(for blockchain: SwappingBlockchain) async throws -> Decimal
}
