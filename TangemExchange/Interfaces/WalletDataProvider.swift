//
//  WalletDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol WalletDataProvider {
    func getWalletAddress(currency: Currency) -> String?
    func getGasModel(
        from: String,
        to: String,
        data: Data,
        sourceCurrency: Currency,
        value: Decimal
    ) async throws -> EthereumGasDataModel

    func getBalance(for currency: Currency) async throws -> Decimal
    func getBalance(for blockchain: ExchangeBlockchain) async throws -> Decimal
}
