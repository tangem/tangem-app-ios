//
//  CombinedExchangeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CombinedExchangeService {
    private let buyService: ExchangeService
    private let sellService: ExchangeService

    init(buyService: ExchangeService, sellService: ExchangeService) {
        self.buyService = buyService
        self.sellService = sellService
    }
}

extension CombinedExchangeService: ExchangeService {
    var successCloseUrl: String {
        buyService.successCloseUrl
    }

    var sellRequestUrl: String {
        sellService.sellRequestUrl
    }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        buyService.canBuy(currencySymbol, amountType: amountType, blockchain: blockchain)
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        sellService.canSell(currencySymbol, amountType: amountType, blockchain: blockchain)
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        buyService.getBuyUrl(currencySymbol: currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: walletAddress)
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        sellService.getSellUrl(currencySymbol: currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: walletAddress)
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        sellService.extractSellCryptoRequest(from: data)
    }

    func initialize() {
        buyService.initialize()
        sellService.initialize()
    }
}
