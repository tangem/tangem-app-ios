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
    let amount: Amount
    let providersFormatted: String
    let timeFormatted: String

    var amountFormatted: AttributedString {
        let string = "\(Localization.onrampUpToRate) \(amount.formatted)"
        var formatted = AttributedString(string)
        formatted.font = Fonts.Regular.caption1
        formatted.foregroundColor = Colors.Text.tertiary

        if let range = formatted.range(of: amount.formatted) {
            formatted[range].foregroundColor = Colors.Text.primary1
        }

        return formatted
    }

    @IgnoredEquatable
    var action: () -> Void

    init(
        paymentMethod: PaymentMethod,
        amount: Amount,
        providersFormatted: String,
        timeFormatted: String,
        action: @escaping () -> Void
    ) {
        self.paymentMethod = paymentMethod
        self.amount = amount
        self.providersFormatted = providersFormatted
        self.timeFormatted = timeFormatted
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
    }
}
