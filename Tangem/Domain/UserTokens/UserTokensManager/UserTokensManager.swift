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

// [REDACTED_TODO_COMMENT]
protocol UserTokensSyncService {
    var initializedPublisher: AnyPublisher<Bool, Never> { get }
}

protocol UserTokensManager: UserTokensReordering, UserTokensSyncService {
    var userTokens: [TokenItem] { get }

    var userTokensPublisher: AnyPublisher<[TokenItem], Never> { get }

    var derivationManager: DerivationManager? { get }

    func deriveIfNeeded(completion: @escaping (Result<Void, Error>) -> Void)

    func contains(_ tokenItem: TokenItem, derivationInsensitive: Bool) -> Bool

    /// Checks if any tokenItem needs derivation by card
    func needsCardDerivation(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) -> Bool

    /// Update storage with derivation. Returns updated items.
    func update(
        itemsToRemove: [TokenItem],
        itemsToAdd: [TokenItem],
        completion: @escaping (Result<UserTokensManagerResult.UpdatedTokenItems, Error>) -> Void
    )

    /// Update storage without derivation
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws

    /// Check condition for adding token
    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws

    /// Default implementation provided. Returns enriched TokenItem.
    func add(_ tokenItem: TokenItem, completion: @escaping (Result<TokenItem, Error>) -> Void)

    /// Returns enriched TokenItems.
    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<[TokenItem], Error>) -> Void)

    /// Add token and retrieve it's address
    func add(_ tokenItem: TokenItem) async throws -> String

    /// Checks whether token can be removed when have pending tokens to add or remove
    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool

    /// Default implementation provided
    func canRemove(_ tokenItem: TokenItem) -> Bool

    func remove(_ tokenItem: TokenItem)

    func sync(completion: @escaping () -> Void)
}

// MARK: - Default implementation

extension UserTokensManager {
    func add(_ tokenItem: TokenItem, completion: @escaping (Result<TokenItem, Error>) -> Void) {
        add([tokenItem]) { result in
            completion(result.map { $0.first ?? tokenItem })
        }
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        canRemove(tokenItem, pendingToAddItems: [], pendingToRemoveItems: [])
    }
}

// MARK: - UserTokensManagerResult

enum UserTokensManagerResult {
    struct UpdatedTokenItems {
        let removed: [TokenItem]
        let added: [TokenItem]
    }
}
