//
//  ExpressAPIError.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressAPIError: Decodable, LocalizedError, Error {
    let code: Int?
    let description: String?
    let value: Value?

    public var codeCase: CodeCase? {
        code.map { CodeCase(rawValue: $0) ?? .unknown }
    }

    public var errorDescription: String? {
        code?.description ?? description
    }
}

public extension ExpressAPIError {
    struct Value: Decodable {
        let minAmount: String
        let decimals: Int

        var amount: Decimal? {
            Decimal(string: minAmount).map { $0 / pow(10, decimals) }
        }
    }

    enum CodeCase: Int, Decodable {
        case unknown

        // Service
        case serverError = 2000
        case badRequestError = 2010
        case forbiddenError = 2020
        case notFoundError = 2030
        case requestLoggerError = 2040

        // ExchangeAdapter
        case eaRequestError = 2110
        case eaRequestTimeoutError = 2120
        case eaInvalidAdapterResponse = 2130

        // CoreError
        case coreError = 2100
        case exchangeInternalError = 2200
        case exchangeProviderNotFoundError = 2210
        case exchangeProviderNotActiveError = 2220
        case exchangeProviderNotAvailableError = 2230
        case exchangeNotPossibleError = 2240
        case exchangeTooSmallAmountError = 2250
        case exchangeInvalidAddressError = 2260
        case exchangeNotEnoughBalanceError = 2270
        case exchangeNotEnoughAllowanceError = 2280
        case ExchangeInvalidDecimalsError = 2290

        case ExchangeTransactionNotFoundError = 2500
    }
}
