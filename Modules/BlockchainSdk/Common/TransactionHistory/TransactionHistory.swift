//
//  TransactionHistory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum TransactionHistory {}

public extension TransactionHistory {
    struct Request: Hashable {
        public let key: Key
        public let walletAddressType: WalletAddressType
        public let amountType: Amount.AmountType
        public let limit: Int

        public init(key: Key, walletAddressType: WalletAddressType, amountType: Amount.AmountType, limit: Int = 20) {
            self.key = key
            self.walletAddressType = walletAddressType
            self.amountType = amountType
            self.limit = limit
        }

        public init(address: String, amountType: Amount.AmountType, limit: Int = 20) {
            self.init(
                key: .address(address),
                walletAddressType: .address(address),
                amountType: amountType,
                limit: limit
            )
        }
    }
}

public extension TransactionHistory.Request {
    enum Key: Hashable {
        case address(String)
        case xpub(String)
    }

    enum WalletAddressType: Hashable {
        case address(String)
        case addresses([String])

        public var addresses: [String] {
            switch self {
            case .address(let address):
                return [address]
            case .addresses(let addresses):
                return addresses
            }
        }
    }
}

public extension TransactionHistory {
    struct Response: Hashable {
        public let records: [TransactionRecord]

        public init(records: [TransactionRecord]) {
            self.records = records
        }
    }
}
