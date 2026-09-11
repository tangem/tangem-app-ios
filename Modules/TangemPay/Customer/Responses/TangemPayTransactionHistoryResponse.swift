//
//  TangemPayTransactionHistoryResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayTransactionHistoryResponse: Codable {
    public let transactions: [Transaction]
}

public extension TangemPayTransactionHistoryResponse {
    struct Transaction: Codable, Equatable {
        public let id: String
        public let transactionType: TransactionType
        public let record: Record

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)

            transactionType = try container.decode(TransactionType.self, forKey: .type)
            switch transactionType {
            case .spend:
                record = .spend(try container.decode(Spend.self, forKey: .spend))
            case .collateral:
                record = .collateral(try container.decode(Collateral.self, forKey: .collateral))
            case .payment:
                record = .payment(try container.decode(Payment.self, forKey: .payment))
            case .fee:
                record = .fee(try container.decode(Fee.self, forKey: .fee))
            case .refund:
                record = .refund(try container.decode(Refund.self, forKey: .refund))
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(transactionType, forKey: .type)
            switch record {
            case .spend(let spend):
                try container.encode(spend, forKey: .spend)
            case .collateral(let collateral):
                try container.encode(collateral, forKey: .collateral)
            case .payment(let payment):
                try container.encode(payment, forKey: .payment)
            case .fee(let fee):
                try container.encode(fee, forKey: .fee)
            case .refund(let refund):
                try container.encode(refund, forKey: .refund)
            }
        }

        enum CodingKeys: CodingKey {
            case id
            case type
            case spend
            case collateral
            case payment
            case fee
            case refund
        }
    }

    enum Record: Equatable {
        case spend(Spend)
        case collateral(Collateral)
        case payment(Payment)
        case fee(Fee)
        case refund(Refund)
    }

    enum TransactionType: String, Codable, Equatable {
        case spend
        case collateral
        case payment
        case fee
        case refund
    }

    struct Spend: Codable, Equatable {
        public let amount: Decimal
        public let currency: String
        public let localAmount: Decimal
        public let localCurrency: String?
        public let authorizedAmount: Decimal?
        public let memo: String?
        public let receipt: Bool
        public let merchantName: String?
        public let merchantCategory: String?
        public let merchantCategoryCode: String?
        public let merchantId: String?
        public let enrichedMerchantIcon: URL?
        public let enrichedMerchantName: String?
        public let enrichedMerchantCategory: String?
        public let cardId: String
        public let cardType: String
        public let cardDisplayName: String?
        public let cardNumberEnd: String?
        public let status: PaymentStatus
        public let declinedReason: String?
        public let authorizedAt: Date
        public let postedAt: Date?
        public let cashback: Decimal?
        public let cashbackStatus: TangemPayCashbackStatus?
        public let cashbackCurrencyCode: String?

        public var isReversed: Bool {
            status == .reversed
        }
    }

    struct Refund: Codable, Equatable {
        public let amount: Decimal
        public let currency: String
        public let localAmount: Decimal?
        public let localCurrency: String?
        public let sourceTransactionId: String?
        public let merchantName: String?
        public let merchantCategory: String?
        public let merchantCategoryCode: String?
        public let merchantId: String?
        public let enrichedMerchantIcon: URL?
        public let enrichedMerchantName: String?
        public let enrichedMerchantCategory: String?
        public let cardId: String
        public let cardType: String
        public let cardDisplayName: String?
        public let cardNumberEnd: String?
        public let status: PaymentStatus
        public let authorizedAt: Date
        public let postedAt: Date?
        public let cashback: Decimal?
        public let cashbackStatus: TangemPayCashbackStatus?
        public let cashbackCurrencyCode: String?
    }

    struct Collateral: Codable, Equatable {
        public let amount: Decimal
        public let currency: String
        public let memo: String?
        public let chainId: Double?
        public let walletAddress: String?
        public let transactionHash: String?
        public let postedAt: Date
    }

    struct Payment: Codable, Equatable {
        public let amount: Decimal
        public let currency: String
        public let memo: String?
        public let chainId: Double?
        public let walletAddress: String?
        public let transactionHash: String?
        public let postedAt: Date
    }

    enum PaymentStatus: String, Codable, Equatable {
        case pending
        case completed
        case declined
        case reversed
        case undefined

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue.lowercased()) ?? .undefined
        }
    }

    struct Fee: Codable, Equatable {
        public let amount: Decimal
        public let currency: String
        public let description: String?
        public let postedAt: Date
    }
}
