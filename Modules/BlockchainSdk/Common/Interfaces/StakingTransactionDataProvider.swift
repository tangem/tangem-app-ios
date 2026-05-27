//
//  StakingTransactionDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol StakingTransactionDataProvider {
    associatedtype RawTransaction

    func prepareDataForSign<T: StakingTransaction>(transaction: T) throws -> Data
    func prepareDataForSend<T: StakingTransaction>(transaction: T, signature: SignatureInfo) throws -> RawTransaction
}
