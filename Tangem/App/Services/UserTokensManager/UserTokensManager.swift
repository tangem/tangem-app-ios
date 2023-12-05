//
//  UserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

protocol UserTokensSyncService {
    var initialized: Bool { get }
    var initializedPublisher: AnyPublisher<Bool, Never> { get }
}

protocol UserTokensManager: UserTokensReordering {
    var derivationManager: DerivationManager? { get }

    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool
    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token]

    /// Update storage with derivation
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    /// Update storage without derivtion
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?)

    /// Check condition for adding token
    func assertCanAdd(_ tokenItem: TokenItem) throws
    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    /// Add token and retrieve it's address
    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?) async throws -> String

    func canRemove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool
    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?)

    func sync(completion: @escaping () -> Void)
}

extension UserTokensManager {
    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            add(tokenItems, derivationPath: derivationPath) { result in
                continuation.resume(with: result)
            }
        }
    }

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        add([tokenItem], derivationPath: derivationPath, completion: completion)
    }
}
