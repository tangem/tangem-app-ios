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
    var operations: [StoredJointAccountPendingOperations] { get }

    var operationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> { get }

    func operationPublisher(id: String, in cryptoAccountId: String) -> AnyPublisher<JointAccountOperation, Never>

    /// Has the operation read anew far more often than its regular pace, for as long as the returned token is kept.
    /// - Returns: `nil` when nothing polls the operation — it is no longer in flight, or joint accounts are off — so
    /// there is no faster pace to ask for.
    /// - Note: The faster pace ends with the operation, whoever still holds the token.
    func requestFrequentUpdates(operationId: String) -> AnyCancellable?

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
