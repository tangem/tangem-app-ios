//
//  JointAccountCreationHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// - Note: Created by [REDACTED_AUTHOR]
/// create the account.
final class JointAccountCreationHelper {
    var hasUnsavedChanges: Bool {
        state.withLock { $0.formData != nil || $0.membersData != nil || $0.creatorName != nil }
    }

    var tangemIconProvider: TangemIconProvider {
        CommonTangemIconProvider(config: userWalletModel.config)
    }

    /// The wallet the account is created in. Stays changeable while the flow runs — the form step lets the user
    /// pick another one.
    var userWalletModel: any UserWalletModel {
        userWalletModelSubject.value
    }

    var userWalletModelPublisher: AnyPublisher<any UserWalletModel, Never> {
        userWalletModelSubject.eraseToAnyPublisher()
    }

    var membersCount: Int? {
        state.withLock { $0.membersData?.membersCount }
    }

    var signersCount: Int? {
        state.withLock { $0.membersData?.signersCount }
    }

    var creatorName: String? {
        state.withLock { $0.creatorName }
    }

    private let userWalletModelSubject: CurrentValueSubject<any UserWalletModel, Never>
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(userWalletModel: any UserWalletModel) {
        userWalletModelSubject = CurrentValueSubject(userWalletModel)
    }

    func update(userWalletModel: any UserWalletModel) {
        userWalletModelSubject.send(userWalletModel)
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

    /// - Returns: The model of the account just created, which the steps that follow are about rather than about
    /// creating anything.
    func createAccount() async throws(AccountEditError) -> any JointAccountModel {
        guard let context = collectedContext() else {
            let message = "A joint account is asked for before every step of the flow contributed its part"
            AccountsLogger.warning(message)
            assertionFailure(message)

            throw .unknownError(Error.incompleteCreationContext)
        }

        let accountModelsManager = userWalletModel.accountModelsManager
        let creationResult = try await accountModelsManager.addJointAccount(context: .creation(context))

        let jointAccountModel = await AccountModelsManagerAccountCreationHelper(accountModelsManager: accountModelsManager)
            .createdJointAccountModel(with: creationResult.derivationIdentity)

        guard let jointAccount = jointAccountModel else {
            throw .unknownError(Error.createdAccountNotFound)
        }

        return jointAccount
    }
}

// MARK: - Error

extension JointAccountCreationHelper {
    /// - Note: Reported to the caller wrapped in `AccountEditError.unknownError`, so these read for whoever opens
    /// the log rather than for the user, whose alert is built from the wrapping error.
    enum Error: String, LocalizedError {
        case incompleteCreationContext
        /// - Note: The account itself is created by [REDACTED_AUTHOR]
        /// follow are about.
        case createdAccountNotFound

        var errorDescription: String? {
            switch self {
            case .incompleteCreationContext: "A step of the creation flow has not contributed its part."
            case .createdAccountNotFound: "The account was created, but has not shown up in the account list in time."
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
