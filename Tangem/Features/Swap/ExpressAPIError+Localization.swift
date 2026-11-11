//
//  ExpressAPIError+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization
import struct TangemUIUtils.AlertBinder

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
        localizedMessage(providerName: nil, currencySymbol: nil)
    }

    func localizedMessage(providerName: String?, currencySymbol: String?) -> String {
        let displayedCode = code ?? errorCode.rawValue

        switch (errorCode, formattedAmount(currencySymbol: currencySymbol)) {
        case (.exchangeInternalError, _):
            return Localization.expressErrorSwapUnavailable(displayedCode)
        case (.exchangeProviderNotActiveError, _), (.exchangeProviderNotAvailableError, _), (.exchangeProviderProviderInternalError, _):
            return Localization.expressErrorSwapPairUnavailable(displayedCode)
        case (.exchangeNotPossibleError, _):
            return Localization.warningExpressPairUnavailableMessage(displayedCode)
        case (.exchangeRoundUpError, _):
            return Localization.expressErrorProviderAmountRoundup(displayedCode, value?.roundUpAmount ?? "")
        case (.exchangeTooSmallAmountError, .some(let amount)):
            return Localization.warningExpressTooMinimalAmountTitle(amount)
        case (.exchangeTooBigAmountError, .some(let amount)):
            return Localization.warningExpressTooMaximumAmountTitle(amount)
        case (.exchangeProviderAddressRejectedError, _):
            return providerName.map { Localization.expressErrorTransactionCannotBeCreated($0, displayedCode) }
                ?? Localization.genericErrorCode(displayedCode)
        default:
            return Localization.genericErrorCode(displayedCode)
        }
    }

    private func formattedAmount(currencySymbol: String?) -> String? {
        guard let amount = value?.amount, let currencySymbol else {
            return nil
        }

        return BalanceFormatter().formatCryptoBalance(amount, currencyCode: currencySymbol)
    }
}

extension ExpressAPIError: BindableError {
    var binder: AlertBinder {
        alertBinder(okAction: {})
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeOkErrorAlert(message: localizedMessage, okAction: okAction)
    }
}

extension Error {
    var localizedExpressMessage: String {
        guard let apiError = self as? ExpressAPIError else {
            return localizedDescription
        }

        return apiError.localizedMessage
    }
}

extension ExpressExchangeDataError: BindableError {
    var binder: AlertBinder {
        alertBinder(okAction: {})
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeOkErrorAlert(message: localizedMessage, okAction: okAction)
    }

    var offersSupport: Bool {
        apiError != nil || isInvalidResponse || underlying is ExpressExchangeDataDecoderError
    }

    var localizedMessage: String {
        switch apiError {
        case .some(let apiError) where apiError.errorCode == .exchangeNotPossibleError:
            Localization.warningExpressPairUnavailableMessageV2(apiError.errorCode.rawValue)
        case .some(let apiError):
            apiError.localizedMessage(providerName: provider.name, currencySymbol: currencySymbol)
        case .none:
            underlying.localizedDescription
        }
    }
}
