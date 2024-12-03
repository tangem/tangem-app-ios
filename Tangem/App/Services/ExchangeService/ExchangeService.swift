//
//  ExchangeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol ExchangeService: AnyObject, Initializable {
    var initializationPublisher: Published<ExchangeServiceState>.Publisher { get }
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

enum ExchangeServiceState: Equatable {
    case initializing
    case initialized
    case failed(ExchangeServiceError)

    enum ExchangeServiceError: LocalizedError {
        case networkError
        case countryNotSupported

        var localizedDescription: String {
            switch self {
            case .networkError:
                return Localization.actionButtonsSomethingWrongAlertMessage
            case .countryNotSupported:
                return Localization.sellingRegionalRestrictionAlertTitle
            }
        }
    }
}

private struct ExchangeServiceKey: InjectionKey {
    static var currentValue: ExchangeService & CombinedExchangeService = CommonCombinedExpressService(
        buyService: MercuryoService(),
        utorgService: nil, // Remove optional from the ExchangeService and set the utorgSID in the CommonKeysManager tore-integrate Utorg
        sellService: MoonPayService()
    )
}

extension InjectedValues {
    var exchangeService: ExchangeService & CombinedExchangeService {
        get { Self[ExchangeServiceKey.self] }
        set { Self[ExchangeServiceKey.self] = newValue }
    }
}
