//
//  TransactionHistory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum TransactionHistory {}

extension TransactionHistory {
    public struct Request: Hashable {
        public let address: String
        public let amountType: Amount.AmountType
        public let limit: Int
        
        public init(address: String, amountType: Amount.AmountType, limit: Int = 20) {
            self.address = address
            self.amountType = amountType
            self.limit = limit
        }
    }
}

extension TransactionHistory {
    public struct Response: Hashable {
        public let records: [TransactionRecord]
        
        public init(records: [TransactionRecord]) {
            self.records = records
        }
    }
}
