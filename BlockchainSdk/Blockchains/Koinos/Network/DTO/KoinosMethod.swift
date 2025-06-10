//
//  KoinosMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
// [REDACTED_INFO]
enum KoinosMethod {}

extension KoinosMethod {
    enum ReadContract {
        struct RequestParams: Encodable {
            let contractId: String
            let entryPoint: Int
            let args: String
        }

        struct Response: Decodable {
            let result: String?
        }
    }
}

extension KoinosMethod {
    enum GetAccountRC {
        struct RequestParams: Encodable {
            let account: String
        }

        struct Response: Decodable {
            let rc: String?
        }
    }
}

extension KoinosMethod {
    enum GetAccountNonce {
        struct RequestParams: Encodable {
            let account: String
        }

        struct Response: Decodable {
            let nonce: String
        }
    }
}

extension KoinosMethod {
    enum GetResourceLimits {
        struct Response: Decodable {
            let resourceLimitData: KoinosProtocol.ResourceLimitData
        }
    }
}

extension KoinosMethod {
    enum SubmitTransaction {
        struct RequestParams: Encodable {
            let transaction: KoinosProtocol.Transaction
            let broadcast: Bool
        }

        struct Response: Decodable {
            let receipt: KoinosProtocol.TransactionReceipt
        }
    }
}

extension KoinosMethod {
    enum GetTransactions {
        struct RequestParams: Encodable {
            let transactionIds: [String]
        }

        struct Response: Decodable {
            let transactions: [KoinosProtocol.TransactionBlock]?
        }
    }
}

extension KoinosMethod {
    enum GetContractId {
        struct Response: Decodable {
            let contractId: String
        }
    }
}
