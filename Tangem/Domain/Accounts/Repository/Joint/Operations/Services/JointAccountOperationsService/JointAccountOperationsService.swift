//
//  JointAccountOperationsService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// What a joint account's operations are made and answered through.
/// - Note: Takes the operation and the wallet apart rather than a `JointAccountPendingOperation`: screens act through a
/// `JointAccountPendingOperationHandle`, which reaches back here — see its `sign(_:)` and `reject()`.
protocol JointAccountOperationsService {
    /// - Returns: The operation as the backend registered it, with this member's signature already counted.
    func createOperation(transaction: BSDKTransaction, in wallet: JointAccountWallet) async throws -> JointAccountOperation
    @discardableResult
    func signOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws -> JointAccountOperation
    func rejectOperation(id: String, in wallet: JointAccountWallet) async throws
}
