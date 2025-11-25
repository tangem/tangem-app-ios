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
    @Injected(\.onrampRepository)
    private var onrampRepository: OnrampRepository

    private let amounts: [Decimal] = [50, 100, 200, 300, 500]
    private let balanceFormatter = BalanceFormatter()

    func presets() -> [Preset]? {
        switch onrampRepository.preferenceCurrency?.identity.code {
        case "USD":
            return makePresets(for: "USD")
        case "EUR":
            return makePresets(for: "EUR")
        default:
            return nil
        }
    }

    private func makePresets(for currencyCode: String) -> [Preset] {
        let options = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 0,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 0)
        )

        return amounts.map { amount in
            let formatted = balanceFormatter.formatFiatBalance(amount, currencyCode: currencyCode, formattingOptions: options)
            return Preset(amount: amount, formatted: formatted)
        }
    }

    struct Preset: Hashable, Identifiable {
        var id: Int { hashValue }

        let amount: Decimal
        let formatted: String
    }
}
