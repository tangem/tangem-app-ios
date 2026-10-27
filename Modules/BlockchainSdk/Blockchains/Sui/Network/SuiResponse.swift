//
//  SuiResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Balance

struct SuiGetCoins {
    struct Coin: Hashable {
        let coinType: String
        let coinObjectId: String
        let version: String
        let digest: String
        let balance: String
        let previousTransaction: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(digest)
        }
    }

    let hasNextPage: Bool
    let data: [Coin]
    let nextCursor: String?
}

struct SuiBalance {
    let coinType: SuiCoinObject.CoinType
    let balance: Decimal
    let addressBalance: Decimal
}

// MARK: - ServiceInfo

struct SuiServiceInfo {
    let chainIdentifier: String
    let epoch: UInt64
}

// MARK: - GasPrice

typealias SuiReferenceGasPrice = String

// MARK: - ExecuteTransaction

struct SuiExecuteTransaction {
    let digest: String
}

// MARK: - DryRunTransaction

struct SuiInspectTransaction {
    let effects: SuiTransaction.SuiTransactionEffects
    let input: SuiTransaction.SuiTransactionData
}

enum SuiTransaction {
    struct GasData {
        let price: String
    }

    struct SuiTransactionData {
        let gasData: GasData
    }

    struct SuiTransactionGasUsed {
        let computationCost: String
        let storageCost: String
        let storageRebate: String
        let nonRefundableStorageFee: String
    }

    struct SuiTransactionEffects {
        struct Status {
            let status: String
        }

        let status: Status
        let gasUsed: SuiTransactionGasUsed

        func isSuccess() -> Bool {
            status.status == "success"
        }
    }
}
