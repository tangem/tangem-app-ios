//
//  TangemPayTransactionHistoryResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayTransactionHistoryResponse: Decodable {
    public let transactions: [Transaction]
}

public extension TangemPayTransactionHistoryResponse {
    struct Transaction: Decodable, Equatable {
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
            }
        }

        enum CodingKeys: CodingKey {
            case id
            case type
            case spend
            case collateral
            case payment
            case fee
        }
    }

    enum Record: Equatable {
        case spend(Spend)
        case collateral(Collateral)
        case payment(Payment)
        case fee(Fee)
    }

    enum TransactionType: String, Decodable, Equatable {
        case spend
        case collateral
        case payment
        case fee
    }

    struct Spend: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let localAmount: Double
        public let localCurrency: String
        public let authorizedAmount: Double
        public let memo: String?
        public let receipt: Bool
        public let merchantName: String?
        public let merchantCategory: String?
        public let merchantCategoryCode: String
        public let merchantId: String?
        public let enrichedMerchantIcon: URL?
        public let enrichedMerchantName: String?
        public let enrichedMerchantCategory: String?
        public let cardId: String
        public let cardType: String
        public let status: String
        public let declinedReason: String?
        public let authorizedAt: Date
        public let postedAt: Date?
    }

    struct Collateral: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let memo: String
        public let chainId: Double
        public let walletAddress: String
        public let transactionHash: String
        public let postedAt: Date
    }

    struct Payment: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let memo: String
        public let chainId: Double
        public let walletAddress: String
        public let transactionHash: String
        public let status: String
        public let postedAt: Date
    }

    struct Fee: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let description: String
        public let postedAt: Date
    }
}
