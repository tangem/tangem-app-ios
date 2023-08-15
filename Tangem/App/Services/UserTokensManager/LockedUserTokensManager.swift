//
//  LockedUserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

struct LockedUserTokensManager: UserTokensManager {
    var isInitialSyncPerformed: Bool { false }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
    
    var derivationManager: DerivationManager? { nil }

    func deriveEntriesWithoutDerivation(_ completion: @escaping () -> Void) {}

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
        return []
    }

    func canRemove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        return false
    }

    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) {}

    func updateUserTokens() {}
}
