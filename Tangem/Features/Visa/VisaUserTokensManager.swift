//
//  VisaUserTokensManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk
import BlockchainSdk

class VisaUserTokensManager: UserTokensManager {
    var derivationManager: (any DerivationManager)?
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> { Just([]).eraseToAnyPublisher() }
    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { Just(.none).eraseToAnyPublisher() }
    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { Just(.byBalance).eraseToAnyPublisher() }

    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}
    func contains(_ tokenItem: TokenItem) -> Bool { false }
    func containsDerivationInsensitive(_ tokenItem: TokenItem) -> Bool { false }
    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token] { [] }
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {}
    func add(_ tokenItem: TokenItem) async throws -> String { "" }
    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<Void, TangemSdkError>) -> Void) {}
    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {}
    func canRemove(_ tokenItem: TokenItem) -> Bool { false }
    func remove(_ tokenItem: TokenItem) {}
    func sync(completion: @escaping () -> Void) {}
    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> { Just(()).eraseToAnyPublisher() }
}
