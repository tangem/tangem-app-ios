//
//  ExchangeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

private typealias ExternalExchangeService = ExchangeService & ExchangeServiceConfigurator

protocol ExchangeService: AnyObject, Initializable {
    var initialized: Published<Bool>.Publisher { get }
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

protocol ExchangeServiceConfigurator {
    func configure(for environment: ExchangeServiceEnvironment)
}

enum ExchangeServiceEnvironment {
    case `default`
    case saltpay
}

private struct ExchangeServiceKey: InjectionKey {
    static var currentValue: ExternalExchangeService = CombinedExchangeService(
        mercuryoService: MercuryoService(),
        utorgService: UtorgService(),
        sellService: MoonPayService()
    )
}

extension InjectedValues {
    var exchangeService: ExchangeService {
        externalExchangeService
    }

    var exchangeServiceConfigurator: ExchangeServiceConfigurator {
        externalExchangeService
    }

    private var externalExchangeService: ExternalExchangeService {
        get { Self[ExchangeServiceKey.self] }
        set { Self[ExchangeServiceKey.self] = newValue }
    }
}
