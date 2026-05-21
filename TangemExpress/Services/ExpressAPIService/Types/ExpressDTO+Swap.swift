//
//  ExpressDTO+Swap.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

extension ExpressDTO {
    enum Swap {
        // MARK: - Common

        struct Provider: Codable {
            typealias Id = String

            let providerId: Id
            let rateTypes: [RateType]

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
                let type: ExpressProviderType?
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
                let status: ExpressTransactionStatus
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
                let status: ExpressTransactionStatus
            }
        }

        // MARK: - History (GET /v1/exchange/history)

        enum History {
            struct Response: Decodable {
                let data: [Record]
                let nextCursor: String
                let hasMore: Bool

                enum CodingKeys: String, CodingKey {
                    case data
                    case nextCursor = "next_cursor"
                    case hasMore = "has_more"
                }
            }

            struct Record: Decodable {
                let txId: String
                let status: ExpressTransactionStatus
                let provider: ExpressDTO.HistoryProvider
                let from: AssetRef
                let to: AssetRef
                let payinHash: String?
                let payoutHash: String?
                let externalTxId: String?
                let externalTxUrl: String?
                let refund: Refund?
                let rateType: ExpressProviderRateType
                // [REDACTED_TODO_COMMENT]
                // Sticking with ISO8601 String -> Date to match every other Express endpoint until
                // the new contract is finalized. Flip to `Int` here (and adjust the mapper) when the
                // backend pins the format.
                // let createdAt: Int
                // let updatedAt: Int
                let createdAt: Date
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case txId = "tx_id"
                    case status
                    case provider
                    case from
                    case to
                    case payinHash = "payin_hash"
                    case payoutHash = "payout_hash"
                    case externalTxId = "external_tx_id"
                    case externalTxUrl = "external_tx_url"
                    case refund
                    case rateType = "rate_type"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                }
            }

            struct AssetRef: Decodable {
                let network: String
                let tokenId: String?
                let rawAmount: String
                let decimals: Int
                let isActual: Bool?

                enum CodingKeys: String, CodingKey {
                    case network
                    case tokenId = "token_id"
                    case rawAmount = "raw_amount"
                    case decimals
                    case isActual = "is_actual"
                }
            }

            struct Refund: Decodable {
                let network: String
                let tokenId: String?
                let rawAmount: String
                let decimals: Int
                let hash: String?

                enum CodingKeys: String, CodingKey {
                    case network
                    case tokenId = "token_id"
                    case rawAmount = "raw_amount"
                    case decimals
                    case hash
                }
            }
        }
    }
}
