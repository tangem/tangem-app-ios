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
            return Localization.bitcoinPromoActivationErrorTitle
        case .noAddress:
            return Localization.bitcoinPromoNoAddressTitle
        case .alreadyActivated:
            return Localization.bitcoinPromoAlreadyActivatedTitle
        case .invalidCode:
            return Localization.bitcoinPromoInvalidCodeTitle
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
