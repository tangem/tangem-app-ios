//
//  JointAccountOperationsServiceMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct JointAccountOperationsServiceMock: JointAccountOperationsService {
    var hasNFCInteraction = false

    func createOperation(transaction: BSDKTransaction, in wallet: JointAccountWallet) async throws -> JointAccountOperation {
        throw CancellationError()
    }

    func signOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws {}

    func rejectOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws {}
}
