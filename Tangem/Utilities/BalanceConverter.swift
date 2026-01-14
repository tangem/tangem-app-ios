//
//  BalanceConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceConverter {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    /// Converts from crypto to fiat using `RatesProvider`. If values doesn't loaded will wait for loading info from backend and return converted value
    /// Will throw error if failed to load quotes or failed to find currency with specified code
    /// - Parameters:
    ///   - value: Amount of crypto to convert to fiat
    ///   - currencyId: ID of the crypto currency
    /// - Returns: Converted decimal value in specified fiat currency
    func convertToFiat(_ value: Decimal, currencyId: String) async throws -> Decimal {
        let rate = try await quotesRepository.quote(for: currencyId).price
        let fiatValue = value * rate
        return fiatValue
    }

    /// Converts a crypto amount to another crypto via fiat as an intermediary.
    /// - Parameters:
    ///   - sourceId: ID of the source crypto asset.
    ///   - sourceAmount: Amount of the source crypto to convert.
    ///   - targetId: ID of the target crypto asset.
    /// - Returns: Equivalent amount in the target crypto.
    /// - Throws: `BalanceConverterError.cannotConvertToCrypto` if target rate is unavailable.
    func convertCryptoToCrypto(sourceId: String, sourceAmount: Decimal, targetId: String) async throws -> Decimal {
        let sourceToFiat = try await convertToFiat(sourceAmount, currencyId: sourceId)

        guard let fiatToTarget = convertToCryptoFrom(fiatValue: sourceToFiat, currencyId: targetId) else {
            throw BalanceConverterError.cannotConvertToCrypto(currencyId: targetId)
        }

        return fiatToTarget
    }

    /// Returns exchange rate between two crypto assets via fiat price.
    /// 1 unit of `from` equals X units of `to`.
    func cryptoToCryptoRate(from sourceAssetId: String, to targetAssetId: String) async throws -> Decimal {
        if sourceAssetId == targetAssetId {
            return 1
        }

        let sourceInFiat = try await convertToFiat(1, currencyId: sourceAssetId)
        let targetInFiat = try await convertToFiat(1, currencyId: targetAssetId)

        guard targetInFiat != 0 else {
            throw BalanceConverterError.invalidTargetPrice
        }

        return sourceInFiat / targetInFiat
    }

    func convertToFiat(_ value: Decimal, currencyId: String) -> Decimal? {
        guard let rate = quotesRepository.quotes[currencyId]?.price else {
            return nil
        }

        let fiatValue = value * rate
        return fiatValue
    }

    /// Converts a fiat value to a crypto amount using the latest available rate.
    /// - Parameters:
    ///   - fiatValue: Amount in fiat currency to convert.
    ///   - currencyId: ID of the target crypto asset.
    /// - Returns: Converted crypto amount, or `nil` if the rate is unavailable.
    func convertToCryptoFrom(fiatValue: Decimal, currencyId: String) -> Decimal? {
        guard let rate = quotesRepository.quotes[currencyId]?.price else {
            return nil
        }

        let cryptoValue = fiatValue / rate
        return cryptoValue
    }
}

extension BalanceConverter {
    enum BalanceConverterError: Error {
        case cannotConvertToCrypto(currencyId: String)
        case invalidTargetPrice
    }
}
