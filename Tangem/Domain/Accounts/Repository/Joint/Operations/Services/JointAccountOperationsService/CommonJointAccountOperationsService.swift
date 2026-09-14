//
//  CommonJointAccountOperationsService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonJointAccountOperationsService {}

// MARK: - JointAccountOperationsService protocol conformance

extension CommonJointAccountOperationsService: JointAccountOperationsService {
    func createOperation(transaction: BSDKTransaction, in walletModel: any WalletModel) async throws {
        // [REDACTED_TODO_COMMENT]
    }

    func signOperation(operation: JointAccountPendingOperation) async throws {
        // [REDACTED_TODO_COMMENT]
    }

    func rejectOperation(operation: JointAccountPendingOperation) async throws {
        // [REDACTED_TODO_COMMENT]
    }
}
