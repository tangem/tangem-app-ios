//
//  PromocodeActivationError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum PromocodeActivationError: LocalizedError {
    case activationError
    case noAddress(currencyName: String)
    case alreadyActivated
    case invalidCode
    case campaignExpired
    case invalidAddress
    case networkError

    var title: String {
        switch self {
        case .activationError, .campaignExpired, .invalidAddress, .networkError:
            return Localization.bitcoinPromoActivationErrorTitle
        case .noAddress(let currencyName):
            return Localization.promoCodeNoAddressTitle(currencyName)
        case .alreadyActivated:
            return Localization.bitcoinPromoAlreadyActivatedTitle
        case .invalidCode:
            return Localization.bitcoinPromoInvalidCodeTitle
        }
    }

    var analyticsErrorCode: String {
        switch self {
        case .activationError:
            return "internal_error"
        case .noAddress:
            return "address_missing"
        case .alreadyActivated:
            return "already_used"
        case .invalidCode:
            return "invalid_code"
        case .campaignExpired:
            return "campaign_expired"
        case .invalidAddress:
            return "invalid_address"
        case .networkError:
            return "network_error"
        }
    }

    var errorDescription: String? {
        switch self {
        case .activationError, .campaignExpired, .invalidAddress, .networkError:
            return Localization.bitcoinPromoActivationError
        case .noAddress(let currencyName):
            return Localization.promoCodeNoAddress(currencyName)
        case .alreadyActivated:
            return Localization.bitcoinPromoAlreadyActivated
        case .invalidCode:
            return Localization.bitcoinPromoInvalidCode
        }
    }
}

extension PromocodeActivationError {
    init(apiCode: TangemAPIError.ErrorCode) {
        switch apiCode {
        case .badRequest:
            self = .invalidAddress
        case .notFound:
            self = .invalidCode
        case .conflict:
            self = .alreadyActivated
        case .unprocessableEntity:
            self = .campaignExpired
        case .unknown:
            self = .networkError
        default:
            self = .activationError
        }
    }
}
