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
/// - Note: Takes the operation and the wallet apart rather than a `JointAccountPendingOperation`, which is the pair
/// the screens are handed and which reaches back here to act — see its `sign()` and `reject()`.
protocol JointAccountOperationsService {
    var hasNFCInteraction: Bool { get }

    /// - Returns: The operation as the backend registered it, with this member's signature already counted.
    func createOperation(transaction: BSDKTransaction, in wallet: JointAccountWallet) async throws -> JointAccountOperation
    func signOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws
    func rejectOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws
}
