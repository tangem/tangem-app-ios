//
//  FiatPresetService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct FiatPresetService {
    private let onrampRepository: OnrampRepository

    private let amounts: [Decimal] = [50, 100, 200, 300]
    private let balanceFormatter = BalanceFormatter()

    init(onrampRepository: OnrampRepository) {
        self.onrampRepository = onrampRepository
    }

    func presets() -> [Preset]? {
        switch onrampRepository.preferenceCurrency?.identity.code {
        case "USD":
            return makePresets(for: "USD", currencySymbol: AppConstants.usdSign)
        case "EUR":
            return makePresets(for: "EUR", currencySymbol: AppConstants.eurSign)
        default:
            return nil
        }
    }

    private func makePresets(for currencyCode: String, currencySymbol: String) -> [Preset] {
        let options = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 0,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 0)
        )

        let formatter = balanceFormatter.makeDefaultFiatFormatter(forCurrencyCode: currencyCode, formattingOptions: options)
        formatter.currencySymbol = currencySymbol

        return amounts.map { amount in
            let formatted = balanceFormatter.formatFiatBalance(amount, currencyCode: currencyCode, formattingOptions: options, formatter: formatter)
            return Preset(amount: amount, formatted: formatted)
        }
    }

    struct Preset: Hashable, Identifiable {
        var id: Int { hashValue }

        let amount: Decimal
        let formatted: String
    }
}
