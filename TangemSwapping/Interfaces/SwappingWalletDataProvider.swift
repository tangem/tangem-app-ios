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
    func getGasModel(
        sourceAddress: String,
        destinationAddress: String,
        data: Data,
        blockchain: SwappingBlockchain,
        value: Decimal,
        gasPolicy: SwappingGasLimitPolicy
    ) async throws -> EthereumGasDataModel

    func getBalance(for currency: Currency) async throws -> Decimal
    func getBalance(for blockchain: SwappingBlockchain) async throws -> Decimal
}

public enum SwappingGasLimitPolicy {
    case noRaise
    case lowRaise
    case mediumRaise
    case highRaise

    public func value(for value: Int) -> Int {
        switch self {
        case .noRaise:
            return value
        case .lowRaise:
            return value * 110 / 100
        case .mediumRaise:
            return value * 125 / 100
        case .highRaise:
            return value * 150 / 100
        }
    }
}
