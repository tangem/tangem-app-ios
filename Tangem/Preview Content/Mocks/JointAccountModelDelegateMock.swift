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
    /// The configs the confirmation was asked for with, in the order they arrived.
    var confirmationConfigs: [JointAccountConfirmationConfig] {
        state.withLockUnchecked { $0.confirmationConfigs }
    }

    /// `uncheckedState` because the error to fail with is an `AccountEditError`, which carries a plain `any Error`.
    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    /// Makes every confirmation from here on fail the way the wallet would report it.
    func failConfirmation(with error: AccountEditError) {
        state.withLockUnchecked { $0.confirmationError = error }
    }

    func commonCryptoAccountModel(
        _ model: CommonCryptoAccountModel,
        wantsToUpdateWith config: CryptoAccountPersistentConfig
    ) async throws(AccountEditError) {}

    func commonCryptoAccountModelWantsToArchive(_ model: CommonCryptoAccountModel) async throws(AccountArchivationError) {}

    func confirmJointAccount(with config: JointAccountConfirmationConfig) async throws(AccountEditError) -> JointAccountStatus {
        let error = state.withLockUnchecked { state in
            state.confirmationConfigs.append(config)
            return state.confirmationError
        }

        if let error {
            throw error
        }

        return .confirming(safeAddress: config.safeAddress)
    }
}

// MARK: - Auxiliary types

private extension JointAccountModelDelegateMock {
    struct State {
        var confirmationConfigs: [JointAccountConfirmationConfig] = []
        var confirmationError: AccountEditError?
    }
}
