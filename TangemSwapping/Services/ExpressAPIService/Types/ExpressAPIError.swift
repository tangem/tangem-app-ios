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

    public var errorCode: Code {
        if let code, let codeCase = Code(rawValue: code) {
            return codeCase
        }

        return .unknown
    }

    public var errorDescription: String? {
        code?.description ?? description
    }
}

public extension ExpressAPIError {
    struct Value: Decodable {
        let currentAllowance: String?
        let minAmount: String?
        let decimals: Int?

        var amount: Decimal? {
            guard let minAmount, let decimals else {
                return nil
            }

            return Decimal(string: minAmount).map { $0 / pow(10, decimals) }
        }
    }

    enum Code: Int, Decodable, LocalizedError {
        case unknown = -1

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
        case exchangeInvalidDecimalsError = 2290

        case exchangeTransactionNotFoundError = 2500

        public var errorDescription: String? {
            rawValue.description
        }
    }
}
