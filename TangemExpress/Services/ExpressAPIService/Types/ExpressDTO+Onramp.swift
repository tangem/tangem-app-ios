//
//  ExpressDTO+Onramp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import AnyCodable

extension ExpressDTO {
    enum Onramp {
        // MARK: - Common

        struct Provider: Decodable {
            let providerId: String
            let paymentMethods: [String]
        }

        struct FiatCurrency: Decodable {
            let name: String
            let code: String
            let image: String?
            let precision: Int
        }

        struct Country: Decodable {
            let name: String
            let code: String
            let image: String?
            let alpha3: String?
            let continent: String?
            let defaultCurrency: FiatCurrency
            let onrampAvailable: Bool
        }

        struct PaymentMethod: Decodable {
            let id: String
            let name: String
            let image: URL
        }

        // MARK: - Pairs

        enum Pairs {
            struct Request: Encodable {
                let fromCurrencyCode: String?
                // alpha2
                let countryCode: String
                let to: [Currency]
            }

            struct Response: Decodable {
                let fromCurrencyCode: String?
                let to: Currency
                let providers: [Provider]
            }
        }

        // MARK: - Quote

        enum Quote {
            struct Request: Encodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromPrecision: Int
                let fromAmount: String
                let toDecimals: Int
                let providerId: String
            }

            struct Response: Decodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let toAmount: String
                let toDecimals: Int
                let providerId: String
                let minFromAmount: String?
                let maxFromAmount: String?
                let minToAmount: String?
                let maxToAmount: String?
                let nativePaymentAvailable: Bool?
                let quoteId: String?
            }
        }

        // MARK: - Data

        enum Data {
            struct Request: Encodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let fromPrecision: Int
                let toDecimals: Int
                let providerId: String
                let toAddress: String
                let toExtraId: String? // Optional, as indicated by `?`
                let redirectUrl: String
                let language: String? // Optional
                let theme: String? // Optional
                let requestId: String // Required unique ID
            }

            struct Response: Decodable {
                let txId: String
                let dataJson: String // Decodes the nested JSON object
                let signature: String
            }

            struct CodedData: Decodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let fromPrecision: Int
                let toAmount: Decimal?
                let providerId: String
                let toAddress: String
                let redirectUrl: URL
                let language: String?
                let theme: String?
                let requestId: String
                let externalTxId: String?
                let externalTxUrl: String?
                let widgetUrl: URL?
            }
        }

        // MARK: - NativePaymentData

        enum NativePaymentData {
            enum PaymentType: String, Encodable {
                case apple
            }

            enum TxType: String, Decodable {
                case nativePayment
                case widget
            }

            struct PaymentData: Encodable {
                let type: PaymentType
                let paymentToken: String
                let quoteId: String
                let userData: UserData
            }

            struct UserData: Encodable {
                let email: String
                let firstName: String?
                let lastName: String?
                let billingAddress: BillingAddress?
            }

            struct BillingAddress: Encodable {
                let city: String?
                let state: String?
                let postalCode: String?
                let country: String?
            }

            struct Request: Encodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let fromPrecision: Int
                let toDecimals: Int
                let providerId: String
                let toAddress: String
                let toExtraId: String?
                let redirectUrl: String
                let language: String?
                let theme: String?
                let requestId: String
                let paymentData: PaymentData?
            }

            struct Response: Decodable {
                let txId: String
                let txType: TxType?
                let dataJson: String
                let signature: String

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    txId = try container.decode(String.self, forKey: .txId)
                    dataJson = try container.decode(String.self, forKey: .dataJson)
                    signature = try container.decode(String.self, forKey: .signature)
                    // Tolerate nil and unknown raw values — fall through to .widget in the mapper.
                    let raw = try container.decodeIfPresent(String.self, forKey: .txType)
                    txType = raw.flatMap(TxType.init(rawValue:))
                }

                private enum CodingKeys: String, CodingKey {
                    case txId
                    case txType
                    case dataJson
                    case signature
                }
            }
        }

        // MARK: - Status

        enum Status {
            struct Request: Encodable {
                let txId: String
            }

            struct Response: Decodable {
                let txId: String
                let providerId: String // Provider's alphanumeric ID
                let payoutAddress: String // Address to which the coins are sent
                let status: String // Status of the transaction
                let failReason: String? // Optional field for failure reason
                let externalTxId: String? // External transaction ID
                let externalTxUrl: String? // Optional URL to track the external transaction
                let payoutHash: String? // Optional payout hash
                let createdAt: String // ISO date for when the transaction was created

                let fromCurrencyCode: String // Source currency
                let fromAmount: String // Amount of the source currency
                let fromPrecision: Int

                // ToAsset information:
                let toContractAddress: String
                let toNetwork: String
                let toDecimals: Int
                let toAmount: String?
                let toActualAmount: String?

                let paymentMethod: String // Payment method used
                let countryCode: String // Country code
            }
        }

        // MARK: - History (initial)

        enum History {
            struct Request: Encodable {
                let payoutAddress: String
                /// Opaque cursor (hence `AnyEncodable`) for the next page.
                let afterCursor: AnyEncodable?
                let limit: Int?
            }

            struct Response: Decodable {
                let items: [Record]
                let pagination: Pagination
            }

            struct Pagination: Decodable {
                /// Opaque cursor (hence `AnyDecodable`) for the next page.
                let endCursor: AnyDecodable?
                /// Opaque cursor (hence `AnyDecodable`) to seed the delta sync.
                let startDeltaCursor: AnyDecodable?
                let hasMore: Bool? // [REDACTED_TODO_COMMENT]
                @available(iOS, deprecated: 100000.0, message: "Temporary fallback, do not use")
                let hasNextPage: Bool? // [REDACTED_TODO_COMMENT]
            }

            struct Record: Decodable {
                let txId: String
                let providerId: String
                let fromAddress: String
                let payinAddress: String
                let payinExtraId: String?
                let payoutAddress: String
                let refundAddress: String?
                let refundExtraId: String?
                let rateType: String
                let status: String
                let externalTxId: String?
                let externalTxStatus: String?
                let externalTxUrl: String?
                let payinHash: String?
                let payoutHash: String?
                let refundNetwork: String?
                let refundContractAddress: String?
                let createdAt: Date
                let updatedAt: Date?
                let payTill: Date?
                let averageDuration: TimeInterval?

                // fromCurrency info
                let fromAmount: String
                let fromCurrencyCode: String
                let fromPrecision: Int

                // toAsset info
                let toContractAddress: String
                let toNetwork: String
                let toDecimals: Int
                let toAmount: String
                let toActualAmount: String?
            }
        }

        // MARK: - History (delta)

        enum HistoryDelta {
            struct Request: Encodable {
                let payoutAddress: String
                /// Opaque cursor (hence `AnyEncodable`) for the next page.
                let beforeCursor: AnyEncodable?
                let limit: Int?
            }

            struct Response: Decodable {
                let items: [History.Record]
                let pagination: Pagination
            }

            struct Pagination: Decodable {
                /// Opaque cursor (hence `AnyDecodable`) for the next page.
                let startCursor: AnyDecodable?
                let hasMore: Bool
            }
        }
    }
}
