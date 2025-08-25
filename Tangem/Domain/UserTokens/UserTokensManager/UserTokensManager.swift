//
//  UserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol UserTokensSyncService {
    var initialized: Bool { get }
    var initializedPublisher: AnyPublisher<Bool, Never> { get }
}

protocol UserTokensManager: UserTokensReordering {
    var derivationManager: DerivationManager? { get }

    func deriveIfNeeded(completion: @escaping (Result<Void, Error>) -> Void)

    func contains(_ tokenItem: TokenItem) -> Bool
    func containsDerivationInsensitive(_ tokenItem: TokenItem) -> Bool
    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token]

    /// Update storage with derivation
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<Void, Error>) -> Void)
    /// Update storage without derivation
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws

    /// Check condition for adding token
    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws
    func add(_ tokenItem: TokenItem, completion: @escaping (Result<Void, Error>) -> Void)
    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<Void, Error>) -> Void)

    /// Add token and retrieve it's address
    func add(_ tokenItem: TokenItem) async throws -> String

    /// Checks whether token can be removed when have pending tokens to add or remove
    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool
    func canRemove(_ tokenItem: TokenItem) -> Bool
    func remove(_ tokenItem: TokenItem)

    func sync(completion: @escaping () -> Void)
}

extension UserTokensManager {
    func add(_ tokenItems: [TokenItem]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            add(tokenItems) { result in
                continuation.resume(with: result)
            }
        }
    }

    func add(_ tokenItem: TokenItem, completion: @escaping (Result<Void, Error>) -> Void) {
        add([tokenItem], completion: completion)
    }
}
