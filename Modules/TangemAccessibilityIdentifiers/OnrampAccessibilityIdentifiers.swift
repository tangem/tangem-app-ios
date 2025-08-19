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
    public static let providerToSLink = "onrampProviderToSLink"
    public static let cryptoAmountLabel = "onrampCryptoAmountLabel"
    public static let residenceButton = "onrampResidenceButton"
    public static let amountInputField = "onrampAmountInputField"
    public static let amountDisplayField = "onrampAmountDisplayField"

    /// Currency selector button (flag + chevron)
    public static let currencySelectorButton = "onrampCurrencySelectorButton"

    /// Pay with block
    public static let payWithBlock = "onrampPayWithBlock"

    // Currency selector screen
    public static let currencySelectorScreenTitle = "onrampCurrencySelectorScreenTitle"
    public static let currencySelectorPopularSection = "onrampCurrencySelectorPopularSection"
    public static let currencySelectorOtherSection = "onrampCurrencySelectorOtherSection"

    /// Currency item elements
    public static func currencyItem(code: String) -> String {
        return "onrampCurrencyItem_\(code)"
    }

    // Providers screen
    public static let providersScreenTitle = "onrampProvidersScreenTitle"
    public static let providersScreenPaymentMethodBlock = "onrampProvidersScreenPaymentMethodBlock"
    public static let providersScreenProvidersList = "onrampProvidersScreenProvidersList"

    /// Provider card elements - using provider name for uniqueness
    public static func providerCard(name: String) -> String {
        return "onrampProviderCard_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    public static func providerIcon(name: String) -> String {
        return "onrampProviderIcon_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    public static func providerName(name: String) -> String {
        return "onrampProviderName_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    public static func providerAmount(name: String) -> String {
        return "onrampProviderAmount_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    // Payment methods screen
    public static let paymentMethodsScreenTitle = "onrampPaymentMethodsScreenTitle"
    public static let paymentMethodsList = "onrampPaymentMethodsList"

    /// Payment method item elements
    public static func paymentMethodCard(id: String) -> String {
        return "onrampPaymentMethodCard_\(id)"
    }

    public static func paymentMethodIcon(id: String) -> String {
        return "onrampPaymentMethodIcon_\(id)"
    }

    public static func paymentMethodName(id: String) -> String {
        return "onrampPaymentMethodName_\(id)"
    }

    // Residence screen
    public static let residenceSearchField = "onrampResidenceSearchField"
    public static let residenceCountrySelector = "onrampResidenceCountrySelector"

    /// Country item elements
    public static func countryItem(code: String) -> String {
        return "onrampCountryItem_\(code)"
    }
}
