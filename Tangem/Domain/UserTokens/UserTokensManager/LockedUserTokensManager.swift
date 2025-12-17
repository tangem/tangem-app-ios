//
//  LockedUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

struct LockedUserTokensManager: UserTokensManager {
    var initializedPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userTokens: [TokenItem] { [] }

    var userTokensPublisher: AnyPublisher<[TokenItem], Never> { .just(output: userTokens) }

    var derivationManager: DerivationManager? { nil }

    func deriveIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func update(
        itemsToRemove: [TokenItem],
        itemsToAdd: [TokenItem],
        completion: @escaping (Result<UserTokensManagerResult.UpdatedTokenItems, Error>) -> Void
    ) {
        let updatedItems = UserTokensManagerResult.UpdatedTokenItems(removed: itemsToRemove, added: itemsToAdd)
        completion(.success(updatedItems))
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {}

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {}

    func add(_ tokenItem: TokenItem) async throws -> String {
        return ""
    }

    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<[TokenItem], Error>) -> Void) {
        completion(.success(tokenItems))
    }

    func contains(_ tokenItem: TokenItem, derivationInsensitive: Bool) -> Bool {
        false
    }

    func needsCardDerivation(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) -> Bool {
        false
    }

    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool {
        false
    }

    func remove(_ tokenItem: TokenItem) {}

    func sync(completion: @escaping () -> Void) {
        completion()
    }
}

// MARK: - UserTokensPushNotificationsRemoteStatusSyncing protocol conformance

extension LockedUserTokensManager: UserTokensPushNotificationsRemoteStatusSyncing {
    func syncRemoteStatus() {}
}

// MARK: - UserTokensReordering protocol conformance

extension LockedUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> { .just(output: []) }

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { .just(output: .none) }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { .just(output: .dragAndDrop) }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> { .just }
}
