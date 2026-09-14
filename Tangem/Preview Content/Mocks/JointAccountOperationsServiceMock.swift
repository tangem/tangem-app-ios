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
    func createOperation(transaction: BSDKTransaction, in walletModel: any WalletModel) async throws {}

    func signOperation(operation: JointAccountPendingOperation) async throws {}

    func rejectOperation(operation: JointAccountPendingOperation) async throws {}
}
