//
//  ExpressPendingTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct ExpressPendingTransactionRecord: Codable {
    let userWalletId: String
    let expressTransactionId: String
    let transactionType: ExpressTransactionType
    let transactionHash: String
    let sourceTokenTxInfo: TokenTxInfo
    let destinationTokenTxInfo: TokenTxInfo
    let fee: Decimal
    let provider: ExpressProvider
    let date: Date
    let externalTxId: String?
    let externalTxURL: String?
}

extension ExpressPendingTransactionRecord {
    struct TokenTxInfo: Codable {
        let tokenItem: TokenItem
        let blockchainNetwork: BlockchainNetwork
        let amount: Decimal
        let isCustom: Bool
    }
}
