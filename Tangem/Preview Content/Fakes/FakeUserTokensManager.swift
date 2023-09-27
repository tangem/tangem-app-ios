//
//  FakeUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

class FakeUserTokensManager: UserTokensManager {
    var derivationManager: DerivationManager?
    var userTokenListManager: UserTokenListManager

    var isInitialSyncPerformed: Bool { userTokenListManager.isInitialSyncPerformed }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { userTokenListManager.initialSyncPublisher }

    init(derivationManager: FakeDerivationManager?, userTokenListManager: FakeUserTokenListManager) {
        self.derivationManager = derivationManager
        self.userTokenListManager = userTokenListManager
    }

    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        completion(.success(()))
    }

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?) async throws -> String {
        ""
    }

    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        derivationManager?.deriveKeys(cardInteractor: CardInteractor(tangemSdk: .init(), cardId: ""), completion: { result in
            completion(result)
        })
    }

    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        userTokenListManager.userTokens.contains(where: { $0.blockchainNetwork == .init(tokenItem.blockchain, derivationPath: derivationPath) })
    }

    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [BlockchainSdk.Token] {
        userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == blockchainNetwork })?.tokens ?? []
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        completion(.success(()))
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?) {}

    func updateUserTokens() {}

    func canRemove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        false
    }

    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) {}

    func updateUserTokens(_ completion: @escaping () -> Void) {}
}

// MARK: - UserTokensReordering protocol conformance

extension FakeUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModel.ID], Never> { .just(output: []) }

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { .just(output: .none) }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { .just(output: .dragAndDrop) }

    func reorder(_ reorderingActions: [UserTokensReorderingAction]) -> AnyPublisher<Void, Never> { .just }
}
