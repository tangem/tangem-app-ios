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
    case noAddress
    case alreadyActivated
    case invalidCode
    
    var title: String {
        switch self {
        case .activationError:
            return Localization.bitcoinPromoNoAddress
        case .noAddress:
            return Localization.bitcoinPromoNoAddress
        case .alreadyActivated:
            return Localization.bitcoinPromoAlreadyActivated
        case .invalidCode:
            return Localization.bitcoinPromoInvalidCode
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .activationError:
            return Localization.bitcoinPromoActivationError
        case .noAddress:
            return Localization.bitcoinPromoNoAddress
        case .alreadyActivated:
            return Localization.bitcoinPromoAlreadyActivated
        case .invalidCode:
            return Localization.bitcoinPromoInvalidCode
        }
    }
}

//public static let bitcoinPromoActivationError = Localization.tr("Localizable", "bitcoin_promo_activation_error")
/////
//public static let bitcoinPromoActivationSuccess = Localization.tr("Localizable", "bitcoin_promo_activation_success")
/////
//public static let bitcoinPromoAlreadyActivated = Localization.tr("Localizable", "bitcoin_promo_already_activated")
/////
//public static let bitcoinPromoInvalidCode = Localization.tr("Localizable", "bitcoin_promo_invalid_code")
/////
//public static let bitcoinPromoNoAddress = Localization.tr("Localizable", "bitcoin_promo_no_address")

// bitcoin_promo_activation_error – ошибка активации
// bitcoin_promo_no_address – нет адреса биткоин
// bitcoin_promo_already_activated – код уже активирован
// bitcoin_promo_invalid_code – код не валиден

// 1. 409 Промо код уже был активирован
// {
//  "error": "Promo code is already activated or invalid"
// }
// 2. 422 Промо программа неактивна
// {
//  "error": "Promo program is not active"
// }
// 3.404 Прмомокод не найден
//
// 4. 400 Отсутствуют обязательные поля в запросе
// {
//  "error": "Invalid request body"
// }
// 5. 500
