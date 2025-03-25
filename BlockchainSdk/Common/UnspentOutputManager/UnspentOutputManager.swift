//
//  UnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UnspentOutputManager {
    func update(outputs: [UnspentOutput], for script: UTXOLockingScript)

    func preImage(amount: UInt64, fee: UInt64, destination: String) throws -> UTXOPreImageTransactionBuilderTransaction
    func preImage(amount: UInt64, feeRate: UInt64, destination: String) throws -> UTXOPreImageTransactionBuilderTransaction

    func allOutputs() -> [ScriptUnspentOutput]
}
