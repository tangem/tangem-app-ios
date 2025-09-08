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
    var derivationManager: DerivationManager?
    var userTokenListManager: UserTokenListManager

    init(derivationManager: FakeDerivationManager?, userTokenListManager: FakeUserTokenListManager) {
        self.derivationManager = derivationManager
        self.userTokenListManager = userTokenListManager
    }

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {}

    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func add(_ tokenItem: TokenItem) async throws -> String {
        ""
    }

    func deriveIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        derivationManager?.deriveKeys(interactor: KeysDerivingMock(), completion: { result in
            completion(result)
        })
    }

    func contains(_ tokenItem: TokenItem) -> Bool {
        userTokenListManager.userTokens.contains(where: { $0.blockchainNetwork == tokenItem.blockchainNetwork })
    }

    func containsDerivationInsensitive(_ tokenItem: TokenItem) -> Bool {
        userTokenListManager.userTokens.contains { $0.blockchainNetwork.blockchain == tokenItem.blockchain }
    }

    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [BlockchainSdk.Token] {
        userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == blockchainNetwork })?.tokens ?? []
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {}

    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool {
        false
    }

    func remove(_ tokenItem: TokenItem) {}

    func sync(completion: @escaping () -> Void) {}
}

// MARK: - UserTokensReordering protocol conformance

extension FakeUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> { .just(output: []) }

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { .just(output: .none) }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { .just(output: .dragAndDrop) }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> { .just }
}
