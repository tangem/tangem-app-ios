//
//  SellService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk

protocol SellService: AnyObject, Initializable {
    var initializationPublisher: Published<SellServiceState>.Publisher { get }
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

enum SellServiceState: Equatable {
    case initializing
    case initialized
    case failed(SellServiceError)

    enum SellServiceError: LocalizedError {
        case networkError
        case countryNotSupported

        var localizedDescription: String {
            switch self {
            case .networkError:
                return Localization.actionButtonsSomethingWrongAlertMessage
            case .countryNotSupported:
                return Localization.sellingRegionalRestrictionAlertMessage
            }
        }
    }
}

struct SellCryptoRequest {
    let currencyCode: String
    let amount: Decimal
    let targetAddress: String
    let tag: String?
}

private struct SellServiceKey: InjectionKey {
    static var currentValue: SellService = MoonPayService()
}

extension InjectedValues {
    var sellService: SellService {
        get { Self[SellServiceKey.self] }
        set { Self[SellServiceKey.self] = newValue }
    }
}
