//
//  ExpressDTO.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ExpressDTO {
    // MARK: - Common

    struct Currency: Codable {
        let contractAddress: String
        let network: String
    }

    struct Provider: Codable {
        let providerId: Id
        let rateTypes: [RateType]

        enum RateType: String, Codable {
            case float
            case fixed
        }

        enum Id: String, Codable {
            case changeNow = "changenow"
            case oneInch = "1inch"
        }
    }

    // MARK: - Assets

    enum Assets {
        struct Request: Encodable {
            let tokensList: [Currency]
        }

        struct Response: Decodable {
            let contractAddress: String
            let network: String
            let exchangeAvailable: Bool
        }
    }

    // MARK: - Pairs

    enum Pairs {
        struct Request: Encodable {
            let from: [Currency]
            let to: [Currency]
        }

        struct Response: Decodable {
            let from: Currency
            let to: Currency
            let providers: [Provider]
        }
    }

    // MARK: - Providers

    enum Providers {
        struct Response: Decodable {
            let id: Provider.Id
            let name: String
            let type: ExpressProviderType
            let imageLarge: String
            let imageSmall: String
        }
    }

    // MARK: - ExchangeQuote

    enum ExchangeQuote {
        struct Request: Encodable {
            let fromContractAddress: String
            let fromNetwork: String
            let toContractAddress: String
            let toNetwork: String
            let toDecimals: Int
            let fromAmount: String
            let fromDecimals: Int
            let providerId: Provider.Id
            let rateType: Provider.RateType
        }

        struct Response: Decodable {
            let fromAmount: String
            let fromDecimals: Int
            let toAmount: String
            let toDecimals: Int
            let minAmount: String
            let allowanceContract: String?
        }
    }

    // MARK: - ExchangeData

    enum ExchangeData {
        struct Request: Encodable {
            let fromContractAddress: String
            let fromNetwork: String
            let toContractAddress: String
            let toNetwork: String
            let toDecimals: Int
            let fromAmount: String
            let fromDecimals: Int
            let providerId: Provider.Id
            let rateType: Provider.RateType
            let toAddress: String // address for receiving token
        }

        struct Response: Decodable {
            let fromAmount: String
            let fromDecimals: Int
            let toAmount: String
            let toDecimals: Int

            let txType: ExpressTransactionType
            // inner tangem-express transaction id
            let txId: String
            // account for debiting tokens (same as toAddress)
            // for CEX doesn't matter from wich address send
            let txFrom: String?
            // swap smart-contract address
            // CEX address for sending transaction
            let txTo: String
            // transaction data
            let txData: String?
            // amount (same as fromAmount)
            let txValue: String
            // CEX provider transaction id
            let externalTxId: String?
            // url of CEX porider exchange status page
            let externalTxUrl: String?
        }
    }

    // MARK: - ExchangeStatus

    enum ExchangeStatus {
        struct Request: Encodable {
            let txId: String
        }

        struct Response: Decodable {
            let providerId: Provider.Id
            let externalTxId: String
            let externalTxStatus: ExpressTransactionStatus
            let externalTxUrl: String
        }
    }

    // MARK: - Error

    enum APIError {
        struct Response: Decodable {
            let error: ExpressAPIError
        }
    }

    struct ExpressAPIError: Decodable, LocalizedError, Error {
        let code: Code?
        let description: String?
        let value: MinAmountValue?

        struct MinAmountValue: Decodable {
            let minAmount: String
            let decimals: Int

            var amount: Decimal? {
                Decimal(string: minAmount).map { $0 / pow(10, decimals) }
            }
        }

        var errorDescription: String? {
            description
        }

        enum Code: Int, Decodable {
            case badRequest = 2010
            case exchangeProviderNotFoundError = 2210
            case exchangeProviderNotActiveError = 2220
            case exchangeProviderNotAvailableError = 2230
            case exchangeNotPossibleError = 2240
            case exchangeTooSmallAmountError = 2250
            case exchangeInvalidAddressError = 2260
            case exchangeNotEnoughBalanceError = 2270
            case exchangeNotEnoughAllowanceError = 2280
        }
    }
}
