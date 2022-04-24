//
//  ExchangeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol ExchangeService: AnyObject {
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

struct SellCryptoRequest {
    let currencyCode: String
    let amount: Decimal
    let targetAddress: String
}
