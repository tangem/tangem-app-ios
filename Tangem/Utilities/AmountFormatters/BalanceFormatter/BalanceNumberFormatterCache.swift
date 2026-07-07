//
//  BalanceNumberFormatterCache.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `NumberFormatter` is thread-safe on iOS, so these cached instances can be shared across threads.
enum BalanceNumberFormatterCache {
    private static let cache = NSCacheWrapper<CacheKey, NumberFormatter>()

    static func fiatFormatter(
        forCurrencyCode currencyCode: String,
        locale: Locale,
        formattingOptions: BalanceFormattingOptions
    ) -> NumberFormatter {
        cachedFormatter(
            key: CacheKey(kind: .fiat, localeIdentifier: locale.identifier, currencyCode: currencyCode, formattingOptions: formattingOptions)
        ) {
            BalanceFormatter().makeDefaultFiatFormatter(forCurrencyCode: currencyCode, locale: locale, formattingOptions: formattingOptions)
        }
    }

    static func cryptoFormatter(
        forCurrencyCode currencyCode: String,
        locale: Locale,
        formattingOptions: BalanceFormattingOptions
    ) -> NumberFormatter {
        cachedFormatter(
            key: CacheKey(kind: .crypto, localeIdentifier: locale.identifier, currencyCode: currencyCode, formattingOptions: formattingOptions)
        ) {
            BalanceFormatter().makeDefaultCryptoFormatter(forCurrencyCode: currencyCode, locale: locale, formattingOptions: formattingOptions)
        }
    }

    static func decimalFormatter(formattingOptions: BalanceFormattingOptions) -> NumberFormatter {
        cachedFormatter(
            key: CacheKey(kind: .decimal, localeIdentifier: Locale.current.identifier, currencyCode: nil, formattingOptions: formattingOptions)
        ) {
            BalanceFormatter().makeDecimalFormatter(formattingOptions: formattingOptions)
        }
    }

    static func attributedTotalFormatter() -> NumberFormatter {
        cachedFormatter(
            key: CacheKey(kind: .attributedTotal, localeIdentifier: Locale.current.identifier, currencyCode: nil, formattingOptions: nil)
        ) {
            BalanceFormatter().makeAttributedTotalBalanceFormatter()
        }
    }

    private static func cachedFormatter(key: CacheKey, make: () -> NumberFormatter) -> NumberFormatter {
        if let cached = cache.value(forKey: key) {
            return cached
        }

        let formatter = make()
        cache.setValue(formatter, forKey: key)
        return formatter
    }
}

// MARK: - Auxiliary types

private extension BalanceNumberFormatterCache {
    struct CacheKey: Hashable {
        enum Kind: Hashable {
            case fiat
            case crypto
            case decimal
            case attributedTotal
        }

        let kind: Kind
        let localeIdentifier: String
        let currencyCode: String?
        let formattingOptions: BalanceFormattingOptions?
    }
}
