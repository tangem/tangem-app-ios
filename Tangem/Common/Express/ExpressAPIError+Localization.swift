//
//  ExpressAPIError+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

extension ExpressAPIError {
    var localizedTitle: String {
        switch errorCode {
        case .exchangeNotPossibleError:
            Localization.warningExpressPairUnavailableTitle
        default:
            Localization.warningExpressRefreshRequiredTitle
        }
    }

    var localizedMessage: String {
        switch errorCode {
        case .exchangeInternalError:
            return Localization.expressErrorSwapUnavailable(errorCode.rawValue)
        case .exchangeProviderNotActiveError, .exchangeProviderNotAvailableError, .exchangeProviderProviderInternalError:
            return Localization.expressErrorSwapPairUnavailable(errorCode.rawValue)
        case .exchangeNotPossibleError:
            return Localization.warningExpressPairUnavailableMessage(errorCode.rawValue)
        default:
            return Localization.expressErrorCode(errorCode.localizedDescription)
        }
    }
}
