//
//  StakeKitTransactionDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionDataConvertible {
    // This protocol can be empty for now, just used as a constraint
}

protocol StakeKitTransactionDataProvider {
    associatedtype RawTransaction

    func prepareDataForSign<T: TransactionDataConvertible>(transaction: T) throws -> Data
    func prepareDataForSend<T: TransactionDataConvertible>(transaction: T, signature: SignatureInfo) throws -> RawTransaction
}
