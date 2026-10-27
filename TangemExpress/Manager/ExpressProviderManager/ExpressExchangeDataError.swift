//
//  ExpressExchangeDataError.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressExchangeDataError: LocalizedError {
    public let provider: ExpressProvider
    public let currencySymbol: String
    public let underlying: Error

    public var apiError: ExpressAPIError? {
        underlying as? ExpressAPIError
    }

    public var hidesProvider: Bool {
        switch provider.id {
        case "changehero":
            apiError?.errorCode == .exchangeProviderAddressRejectedError
        case "changelly":
            apiError.map { !Self.changellyUserFixableCodes.contains($0.errorCode) } ?? true
        default:
            false
        }
    }

    public var errorDescription: String? {
        underlying.localizedDescription
    }

    private static let changellyUserFixableCodes: Set<ExpressAPIError.Code> = [
        .exchangeTooSmallAmountError,
        .exchangeTooBigAmountError,
        .exchangeInvalidAmountError,
        .exchangeNotEnoughBalanceError,
        .exchangeNotEnoughAllowanceError,
        .exchangeNotEnoughBalanceForGasFeeError,
        .exchangeRoundUpError,
    ]
}
