//
//  ExchangeFacade.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeFacade {
    func sendSwapTransaction(destinationAddress: String,
                             amount: String,
                             gas: String,
                             gasPrice: String,
                             txData: Data,
                             sourceItem: ExchangeItem) async throws

    func submitPermissionForToken(destinationAddress: String,
                                  gasPrice: String,
                                  txData: Data,
                                  for item: ExchangeItem) async throws

    func fetchTxDataForSwap(amount: String,
                            slippage: Int,
                            items: ExchangeItems) async throws -> ExchangeSwapDataModel

    func fetchExchangeAmountLimit(for item: ExchangeItem) async
    func approveTxData(for item: ExchangeItem) async throws -> ExchangeApprovedDataModel
    func getSpenderAddress() async throws -> String
}
