//
//  JointAccountModelDelegateMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// - Warning: Held weakly by the model it is handed to, so whoever builds a model with one of these keeps it alive
/// for as long as the model is used.
final class JointAccountModelDelegateMock: JointAccountModelDelegate {
    /// The configs the activation was asked for with, in the order they arrived.
    var activationConfigs: [JointAccountActivationConfig] {
        state.withLockUnchecked { $0.activationConfigs }
    }

    /// `uncheckedState` because the error to fail with is an `AccountEditError`, which carries a plain `any Error`.
    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    /// Makes every activation from here on fail the way the wallet would report it.
    func failActivation(with error: AccountEditError) {
        state.withLockUnchecked { $0.activationError = error }
    }

    func commonCryptoAccountModel(
        _ model: CommonCryptoAccountModel,
        wantsToUpdateWith config: CryptoAccountPersistentConfig
    ) async throws(AccountEditError) {}

    func commonCryptoAccountModelWantsToArchive(_ model: CommonCryptoAccountModel) async throws(AccountArchivationError) {}

    func activateJointAccount(with config: JointAccountActivationConfig) async throws(AccountEditError) {
        let error = state.withLockUnchecked { state in
            state.activationConfigs.append(config)
            return state.activationError
        }

        if let error {
            throw error
        }
    }
}

// MARK: - Auxiliary types

private extension JointAccountModelDelegateMock {
    struct State {
        var activationConfigs: [JointAccountActivationConfig] = []
        var activationError: AccountEditError?
    }
}
