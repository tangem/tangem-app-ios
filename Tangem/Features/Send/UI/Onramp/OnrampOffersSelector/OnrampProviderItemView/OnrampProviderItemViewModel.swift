//
//  OnrampProviderItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemAssets
import TangemLocalization

struct OnrampProviderItemViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let paymentMethod: PaymentMethod
    let amountType: AmountType
    let providersInfo: ProvidersInfo?

    var isAvailable: Bool {
        switch amountType {
        case .available: true
        case .availableFrom, .availableUpTo: false
        }
    }

    @IgnoredEquatable
    var action: () -> Void

    init(
        paymentMethod: PaymentMethod,
        amountType: AmountType,
        providersInfo: ProvidersInfo?,
        action: @escaping () -> Void
    ) {
        self.paymentMethod = paymentMethod
        self.amountType = amountType
        self.providersInfo = providersInfo
        self.action = action
    }
}

extension OnrampProviderItemViewModel {
    struct PaymentMethod: Hashable {
        let id: String
        let name: String
        let iconURL: URL?
    }

    struct Amount: Hashable {
        let formatted: String
        let badge: OnrampAmountBadge.Badge?

        var attributedFormatted: AttributedString {
            let string = "\(Localization.onrampUpToRate) \(formatted)"
            var formatted = AttributedString(string)
            formatted.font = Fonts.Regular.caption1
            formatted.foregroundColor = Colors.Text.tertiary

            if let range = formatted.range(of: self.formatted) {
                formatted[range].foregroundColor = Colors.Text.primary1
            }

            return formatted
        }
    }

    enum AmountType: Hashable {
        case availableFrom(amount: String)
        case availableUpTo(amount: String)
        case available(Amount)
    }

    struct ProvidersInfo: Hashable {
        let providersFormatted: String
        let timeFormatted: String
    }
}
