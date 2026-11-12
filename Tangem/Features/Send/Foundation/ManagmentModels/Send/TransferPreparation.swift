//
//  TransferPreparation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TransferPreparation {
    func gas(mainCall: TransferPreparationCall) async -> TransferPreparationGas?
    func send(mainCall: BSDKTransaction, gas: TransferPreparationGas) async throws -> TransactionDispatcherResult
}

struct TransferPreparationCall: Equatable {
    let destination: String
    let value: Decimal
    let data: Data
}

struct TransferPreparationGas: Equatable {
    let preparation: Int
    let mainCall: Int

    var total: Int {
        preparation + mainCall
    }
}

enum TransferPreparationGasState: Equatable {
    case estimating
    case estimated
    case reverted
}

enum TransferPreparationError: Error {
    case simulationReverted
}
