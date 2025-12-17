//
//  FakeUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeUserTokensManager: UserTokensManager {
    var initializedPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userTokens: [TokenItem] {
        let converter = StorageEntryConverter()
        return converter.convertToTokenItems(userTokenListManager.userTokensList.entries)
    }

    var userTokensPublisher: AnyPublisher<[TokenItem], Never> {
        let converter = StorageEntryConverter()
        return userTokenListManager.userTokensListPublisher
            .map { converter.convertToTokenItems($0.entries) }
            .eraseToAnyPublisher()
    }

    var derivationManager: DerivationManager?
    var userTokenListManager: UserTokenListManager

    init(derivationManager: FakeDerivationManager?, userTokenListManager: FakeUserTokenListManager) {
        self.derivationManager = derivationManager
        self.userTokenListManager = userTokenListManager
    }

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {}

    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<[TokenItem], Error>) -> Void) {
        completion(.success(tokenItems))
    }

    func add(_ tokenItem: TokenItem) async throws -> String {
        ""
    }

    func deriveIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        derivationManager?.deriveKeys(completion: completion)
    }

    func contains(_ tokenItem: TokenItem, derivationInsensitive: Bool) -> Bool {
        return userTokens.contains { userToken in
            return derivationInsensitive
                ? userToken.blockchainNetwork.blockchain == tokenItem.blockchain
                : userToken.blockchainNetwork == tokenItem.blockchainNetwork
        }
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<UserTokensManagerResult.UpdatedTokenItems, Error>) -> Void) {
        let updatedItems = UserTokensManagerResult.UpdatedTokenItems(removed: itemsToRemove, added: itemsToAdd)
        completion(.success(updatedItems))
    }

    func needsCardDerivation(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) -> Bool {
        true
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {}

    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool {
        false
    }

    func remove(_ tokenItem: TokenItem) {}

    func sync(completion: @escaping () -> Void) {
        completion()
    }
}

// MARK: - UserTokensReordering protocol conformance

extension FakeUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> { .just(output: []) }

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { .just(output: .none) }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { .just(output: .dragAndDrop) }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> { .just }
}
