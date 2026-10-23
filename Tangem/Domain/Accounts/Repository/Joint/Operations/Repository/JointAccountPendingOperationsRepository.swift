//
//  JointAccountPendingOperationsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol JointAccountPendingOperationsRepository {
    var pendingOperations: [StoredJointAccountPendingOperations] { get }

    /// - Note: Kept apart from the accounts as well: an operation moves on its own occasions — a co-signer answers,
    /// the relayer executes — and none of them is a change to the account it belongs to.
    var pendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> { get }

    /// Registers the operation a member signed and stores it among the account's.
    /// - Returns: The operation as the endpoint registered it, with that signature already counted.
    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation

    /// Counts a member's signature towards the threshold and stores the operation as the endpoint now reports it.
    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data, forCryptoAccountId cryptoAccountId: String) async throws

    /// Declines the operation on a member's behalf.
    /// - Note: An answer carrying nothing is the endpoint saying the operation is gone, so it is dropped rather than
    /// stored.
    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws
}
