//
//  P2PTransactionDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol P2PTransactionDataProvider {
    associatedtype RawTransaction

    func prepareDataForSign(transaction: P2PTransaction) throws -> Data
    func prepareDataForSend(transaction: P2PTransaction, signature: SignatureInfo) throws -> RawTransaction
}
