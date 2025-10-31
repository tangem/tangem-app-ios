//
//  OnrampAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum OnrampAccessibilityIdentifiers {
    public static let settingsButton = "onrampSettingsButton"
    public static let residenceButton = "onrampResidenceButton"
    public static let amountInputField = "onrampAmountInputField"
    public static let currencySymbolPrefix = "onrampCurrencySymbolPrefix"

    /// Currency selector button (flag + chevron)
    public static let currencySelectorButton = "onrampCurrencySelectorButton"

    /// All offers button
    public static let allOffersButton = "onrampAllOffersButton"

    // Currency selector screen
    public static let currencySelectorPopularSection = "onrampCurrencySelectorPopularSection"
    public static let currencySelectorOtherSection = "onrampCurrencySelectorOtherSection"

    /// Currency item elements
    public static func currencyItem(code: String) -> String {
        return "onrampCurrencyItem_\(code)"
    }

    /// Providers screen
    public static let providersScreenTitle = "onrampProvidersScreenTitle"

    /// Provider card elements - using provider name for uniqueness
    public static func providerAmount(name: String) -> String {
        return "onrampProviderAmount_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    /// Payment methods screen
    public static let paymentMethodCard = "onrampPaymentMethodCard"

    /// Payment method item elements
    public static func paymentMethodIcon(id: String) -> String {
        return "onrampPaymentMethodIcon_\(id)"
    }

    public static func paymentMethodName(id: String) -> String {
        return "onrampPaymentMethodName_\(id)"
    }

    /// Residence screen
    public static let residenceSearchField = "onrampResidenceSearchField"

    /// Country item elements
    public static func countryItem(code: String) -> String {
        return "onrampCountryItem_\(code)"
    }
}
