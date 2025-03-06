//
//  VisaTransactionRecord.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaTransactionHistoryDTO: Decodable {
    public let cardWalletAddress: String
    public let transactions: [VisaTransactionRecord]

    public struct APIRequest: Encodable {
        let customerId: String
        let productInstanceId: String
        let offset: Int
        let numberOfItems: Int

        public init(customerId: String, productInstanceId: String, offset: Int, numberOfItems: Int) {
            self.customerId = customerId
            self.productInstanceId = productInstanceId
            self.offset = offset
            self.numberOfItems = numberOfItems
        }
    }
}

public struct VisaTransactionRecord: Decodable, Equatable {
    public let id: UInt64
    public let type: String
    public let status: String
    public let date: Date?

    public let blockchainAmount: Decimal
    public let blockchainCoinName: String
    public let transactionAmount: Decimal
    public let transactionCurrencyCode: Int
    public let billingAmount: Decimal
    public let billingCurrencyCode: Int
    public let merchantName: String?
    public let merchantCity: String?
    public let merchantCountryCode: String?
    public let merchantCategoryCode: String?
    public let authCode: String?
    public let rrn: String?
    public let localDate: Date?
    public let requests: [VisaTransactionRecordBlockchainRequest]

    private enum CodingKeys: String, CodingKey {
        case id = "transactionId"
        case type = "transactionType"
        case status = "transactionStatus"
        case date = "transactionDt"
        case localDate = "localDt"
        case blockchainAmount
        case blockchainCoinName
        case transactionAmount
        case transactionCurrencyCode
        case billingAmount
        case billingCurrencyCode
        case merchantName
        case merchantCity
        case merchantCountryCode
        case merchantCategoryCode
        case authCode
        case rrn
        case requests
    }
}

public struct VisaTransactionRecordBlockchainRequest: Decodable, Equatable {
    public let id: UInt64
    public let type: String
    public let status: String
    public let blockchainAmount: Decimal
    public let transactionAmount: Decimal
    public let transactionCurrencyCode: Int
    public let billingAmount: Decimal
    public let billingCurrencyCode: Int
    public let errorCode: Int
    public let date: Date
    public let transactionHash: String?
    public let transactionStatus: String?

    private enum CodingKeys: String, CodingKey {
        case id = "transactionRequestId"
        case type = "requestType"
        case status = "requestStatus"
        case blockchainAmount
        case transactionAmount
        case transactionCurrencyCode
        case billingAmount
        case billingCurrencyCode
        case errorCode
        case date = "requestDt"
        case transactionHash = "txHash"
        case transactionStatus = "txStatus"
    }
}
