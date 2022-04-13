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
    
    func canBuy(_ currencySymbol: String, blockchain: Blockchain) -> Bool {
        buyService.canBuy(currencySymbol, blockchain: blockchain)
    }
    
    func canSell(_ currencySymbol: String, blockchain: Blockchain) -> Bool {
        sellService.canSell(currencySymbol, blockchain: blockchain)
    }
    
    func getBuyUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        buyService.getBuyUrl(currencySymbol: currencySymbol, blockchain: blockchain, walletAddress: walletAddress)
    }
    
    func getSellUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        sellService.getSellUrl(currencySymbol: currencySymbol, blockchain: blockchain, walletAddress: walletAddress)
    }
    
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        sellService.extractSellCryptoRequest(from: data)
    }
}
