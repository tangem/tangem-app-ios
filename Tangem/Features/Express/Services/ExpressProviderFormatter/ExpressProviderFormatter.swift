//
//  ExpressProviderFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemExpress
import UIKit

struct ExpressProviderFormatter {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    let balanceFormatter: BalanceFormatter

    init(balanceFormatter: BalanceFormatter = .init()) {
        self.balanceFormatter = balanceFormatter
    }

    func mapToBadge(availableProvider: ExpressAvailableProvider) -> ProviderBadge? {
        let state: ExpressProviderManagerState = availableProvider.getState()

        if ukGeoDefiner.isUK, ExpressConstants.expressProvidersFCAWarningList.contains(availableProvider.provider.id) {
            return .fcaWarning
        }

        if state.isPermissionRequired {
            return .permissionNeeded
        }

        let canShowBest = !ukGeoDefiner.isUK
        let isBest = availableProvider.isBest

        return canShowBest && isBest ? .bestRate : .none
    }

    func mapToRateSubtitle(
        state: ExpressProviderManagerState,
        senderCurrencyCode: String?,
        destinationCurrencyCode: String?,
        option: RateSubtitleFormattingOption
    ) -> ProviderRowViewModel.Subtitle {
        switch state {
        case .error(_, .none):
            return .text(AppConstants.emDashSign)
        case .restriction(.tooSmallAmount(let minAmount), .none):
            guard let senderCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(minAmount, currencyCode: senderCurrencyCode)
            return .text(Localization.expressProviderMinAmount(formatted))
        case .restriction(.tooBigAmount(let maxAmount), .none):
            guard let senderCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(maxAmount, currencyCode: senderCurrencyCode)
            return .text(Localization.expressProviderMaxAmount(formatted))
        default:
            guard let quote = state.quote else {
                return .text(AppConstants.emDashSign)
            }

            return mapToRateSubtitle(
                fromAmount: quote.fromAmount,
                toAmount: quote.expectAmount,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: option
            )
        }
    }

    func mapToRateSubtitle(
        fromAmount: Decimal,
        toAmount: Decimal,
        senderCurrencyCode: String?,
        destinationCurrencyCode: String?,
        option: RateSubtitleFormattingOption
    ) -> ProviderRowViewModel.Subtitle {
        switch option {
        case .exchangeRate:
            guard let senderCurrencyCode, let destinationCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let rate = toAmount / fromAmount
            let formattedSourceAmount = balanceFormatter.formatCryptoBalance(1, currencyCode: senderCurrencyCode)
            let formattedDestinationAmount = balanceFormatter.formatCryptoBalance(rate, currencyCode: destinationCurrencyCode)

            return .text("\(formattedSourceAmount) ≈ \(formattedDestinationAmount)")
        case .exchangeReceivedAmount:
            guard let destinationCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(toAmount, currencyCode: destinationCurrencyCode)
            return .text(formatted)
        }
    }

    func mapToProvider(provider: ExpressProvider) -> ProviderRowViewModel.Provider {
        ProviderRowViewModel.Provider(
            id: provider.id,
            iconURL: provider.imageURL,
            name: provider.name,
            type: provider.type.title
        )
    }

    func mapToProvider(provider: ExpressPendingTransactionRecord.Provider) -> ProviderRowViewModel.Provider {
        ProviderRowViewModel.Provider(
            id: provider.id,
            iconURL: provider.iconURL,
            name: provider.name,
            type: provider.type.title
        )
    }
}

private extension ExpressProviderType {
    var title: String {
        switch self {
        case .dex, .cex, .onramp, .unknown:
            return rawValue.uppercased()
        case .dexBridge:
            return "DEX/Bridge"
        }
    }
}

private extension ExpressPendingTransactionRecord.ProviderType {
    var title: String {
        switch self {
        case .dex, .cex, .onramp:
            return rawValue.uppercased()
        case .unknown:
            return "unknown"
        case .dexBridge:
            return "DEX/Bridge"
        }
    }
}

extension ExpressProviderFormatter {
    enum RateSubtitleFormattingOption {
        /// How many destination's tokens user will get for the 1 token of source
        case exchangeRate

        /// How many destination's tokens user will get at the end of swap
        case exchangeReceivedAmount
    }

    enum ProviderBadge {
        case permissionNeeded
        case fcaWarning
        case bestRate
    }
}
