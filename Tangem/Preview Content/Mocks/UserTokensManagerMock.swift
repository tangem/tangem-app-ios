//
//  UserTokensManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

struct UserTokensManagerMock: UserTokensManager {
    var isInitialSyncPerformed: Bool { true }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var derivationManager: DerivationManager? { nil }

    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?) {}

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?) async throws -> String {
        return ""
    }

    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}

    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        return false
    }

    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token] {
        []
    }

    func canRemove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        return false
    }

    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) {}

    func updateUserTokens() {}
}

// MARK: - UserTokensReordering protocol conformance

extension UserTokensManagerMock: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModel.ID], Never> { .just(output: []) }

    var groupingOption: AnyPublisher<OrganizeTokensOptions.Grouping, Never> { .just(output: .none) }

    var sortingOption: AnyPublisher<OrganizeTokensOptions.Sorting, Never> { .just(output: .dragAndDrop) }

    func reorder(_ reorderingActions: [UserTokensReorderingAction]) -> AnyPublisher<Void, Never> { .just }
}
