//
//  ExchangeService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeService: AnyObject {
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }
    var canBuyCrypto: Bool { get }
    var canSellCrypto: Bool { get }
    func canBuy(_ currency: String) -> Bool
    func canSell(_ currency: String) -> Bool
    func getBuyUrl(currencySymbol: String, walletAddress: String) -> URL?
    func getSellUrl(currencySymbol: String, walletAddress: String) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

struct SellCryptoRequest {
    let currencyCode: String
    let amount: Decimal
    let targetAddress: String
}
