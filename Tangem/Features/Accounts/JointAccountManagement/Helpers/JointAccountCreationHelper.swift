//
//  JointAccountCreationHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// - Note: Created by [REDACTED_AUTHOR]
/// create the account.
final class JointAccountCreationHelper {
    var hasUnsavedChanges: Bool {
        state.withLock { $0.formData != nil || $0.membersData != nil || $0.creatorName != nil }
    }

    var tangemIconProvider: TangemIconProvider {
        CommonTangemIconProvider(config: userWalletConfig)
    }

    var membersCount: Int? {
        state.withLock { $0.membersData?.membersCount }
    }

    var creatorName: String? {
        state.withLock { $0.creatorName }
    }

    private let userWalletConfig: UserWalletConfig
    private let accountModelsManager: AccountModelsManager
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        userWalletConfig: UserWalletConfig,
        accountModelsManager: AccountModelsManager
    ) {
        self.userWalletConfig = userWalletConfig
        self.accountModelsManager = accountModelsManager
    }

    func update(name: String, icon: AccountModel.CompositeIcon) {
        state.withLock { $0.formData = FormData(name: name, icon: icon) }
    }

    func update(membersCount: Int, signersCount: Int) {
        state.withLock { $0.membersData = MembersData(membersCount: membersCount, signersCount: signersCount) }
    }

    func update(creatorName: String) {
        state.withLock { $0.creatorName = creatorName }
    }

    func createAccount() async throws(AccountEditError) {
        guard let context = collectedContext() else {
            let message = "A joint account is asked for before every step of the flow contributed its part"
            AccountsLogger.warning(message)
            assertionFailure(message)

            throw .unknownError(Error.incompleteCreationContext)
        }

        try await accountModelsManager.addJointAccount(context: context)
    }
}

// MARK: - Error

extension JointAccountCreationHelper {
    enum Error: String, LocalizedError {
        case incompleteCreationContext

        var errorDescription: String? {
            switch self {
            case .incompleteCreationContext: "A step of the creation flow has not contributed its part."
            }
        }
    }
}

// MARK: - Private

private extension JointAccountCreationHelper {
    func collectedContext() -> JointAccountCreationContext? {
        state.withLock { state in
            guard let formData = state.formData,
                  let membersData = state.membersData,
                  let creatorName = state.creatorName else {
                return nil
            }

            return JointAccountCreationContext(
                name: formData.name,
                icon: formData.icon,
                membersCount: membersData.membersCount,
                signersCount: membersData.signersCount,
                creatorName: creatorName
            )
        }
    }
}

// MARK: - Auxiliary types

private extension JointAccountCreationHelper {
    struct State {
        var formData: FormData?
        var membersData: MembersData?
        var creatorName: String?
    }

    struct FormData {
        let name: String
        let icon: AccountModel.CompositeIcon
    }

    struct MembersData {
        let membersCount: Int
        /// How many of the members have to sign for an operation to go through
        let signersCount: Int
    }
}
