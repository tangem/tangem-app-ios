//
//  ExpressDTO+Swap.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import AnyCodable

extension ExpressDTO {
    enum Swap {
        // MARK: - Common

        struct Provider: Codable {
            typealias Id = String

            let providerId: Id
            let rateTypes: [String]

            enum RateType: String, Codable {
                case float
                case fixed
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
                let onrampAvailable: Bool?
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
                let type: String?
                let exchangeOnlyWithinSingleAddress: Bool?
                let imageLarge: String?
                let imageSmall: String?
                let termsOfUse: String?
                let privacyPolicy: String?
                let recommended: Bool?
                let slippage: Decimal?
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
                let fromAmount: String?
                let toAmount: String?
                let fromDecimals: Int
                let providerId: Provider.Id
                let rateType: Provider.RateType
            }

            struct Response: Decodable {
                let fromAmount: String
                let fromDecimals: Int
                let toAmount: String
                let toDecimals: Int
                let allowanceContract: String?
                let quoteId: String?
                let expiredAt: Date?
                let txType: String?
            }
        }

        // MARK: - ExchangeData

        enum ExchangeData {
            struct Request: Encodable {
                let requestId: String
                let quoteId: String?
                let fromAddress: String
                let fromContractAddress: String
                let fromNetwork: String
                let toContractAddress: String
                let toNetwork: String
                let toDecimals: Int
                let fromAmount: String?
                let toAmount: String?
                let fromDecimals: Int
                let providerId: Provider.Id
                let rateType: Provider.RateType
                let toAddress: String // address for receiving token
                let toExtraId: String? // memo/destination tag for recipient
                let refundAddress: String?
                let refundExtraId: String? // typically it's a memo or tag
                let partnerOperationType: String
            }

            struct Response: Decodable {
                // inner tangem-express transaction id
                let txId: String
                let fromAmount: String
                let fromDecimals: Int
                let toAmount: String
                let toDecimals: Int
                let txDetailsJson: String
                let signature: String
                let payTill: Date?
            }
        }

        // MARK: - ExchangeStatus

        enum ExchangeStatus {
            struct Request: Encodable {
                let txId: String
            }

            struct Response: Decodable {
                let providerId: Provider.Id
                let status: String
                let refundNetwork: String?
                let refundContractAddress: String?
                let externalTxId: String?
                let externalTxUrl: String?
                let averageDuration: TimeInterval?
                let createdAt: Date?
            }
        }

        enum ExchangeSent {
            struct Request: Encodable {
                let txHash: String
                let txId: String
                let fromNetwork: String
                let fromAddress: String
                let payinAddress: String
                let payinExtraId: String?
            }

            struct Response: Decodable {
                let txId: String
                let status: String
            }
        }

        // MARK: - History

        enum History {
            struct Response: Decodable {
                let data: [Record]
                let nextCursor: AnyDecodable
                let hasMore: Bool
            }

            struct Record: Decodable {
                let txId: String
                let status: String
                let provider: ExpressDTO.HistoryProvider
                let from: AssetRef
                let to: AssetRef
                let payinHash: String?
                let payoutHash: String?
                let externalTxId: String?
                let externalTxUrl: String?
                let refund: Refund?
                let rateType: String
                // [REDACTED_TODO_COMMENT]
                /*
                 let createdAt: Int
                 let updatedAt: Int
                  */
                let createdAt: Date
                let updatedAt: Date
            }

            struct AssetRef: Decodable {
                let network: String
                let tokenId: String?
                let rawAmount: String
                let decimals: Int
                let isActual: Bool?
            }

            struct Refund: Decodable {
                let network: String
                let tokenId: String?
                let rawAmount: String
                let decimals: Int
                let hash: String?
            }
        }
    }
}
