//
//  CommonJointAccountModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// - Note: Everything a joint account shares with the wallet's own accounts is delegated to the crypto account it is
/// built on, so the two kinds cannot drift apart as that one gains behaviour.
final class CommonJointAccountModel {
    /// Built here rather than held, so that the index it is made of stays this account's own business.
    var derivationIdentity: CryptoAccountDerivationIdentity {
        CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: .joint)
    }

    let policy: JointAccountPolicy

    private(set) var status: JointAccountStatus
    private(set) var members: [JointAccountMember]
    private(set) var invites: [JointAccountInvite]

    private let derivationIndex: Int
    private let cryptoAccount: any CryptoAccountModel
    private let didChangeSubject = PassthroughSubject<Void, Never>()

    init(
        cryptoAccount: any CryptoAccountModel,
        derivationIndex: Int,
        policy: JointAccountPolicy,
        status: JointAccountStatus,
        members: [JointAccountMember],
        invites: [JointAccountInvite]
    ) {
        self.cryptoAccount = cryptoAccount
        self.derivationIndex = derivationIndex
        self.policy = policy
        self.status = status
        self.members = members
        self.invites = invites
    }
}

// MARK: - AccountModelEditable protocol conformance

extension CommonJointAccountModel {
    @discardableResult
    func update(with editor: (_ editor: CommonJointAccountModelEditor) -> Void) -> Self {
        let jointAccountModelEditor = CommonJointAccountModelEditor()
        editor(jointAccountModelEditor)

        cryptoAccount.update { cryptoAccountModelEditor in
            jointAccountModelEditor.name.map(cryptoAccountModelEditor.setName)
            jointAccountModelEditor.icon.map(cryptoAccountModelEditor.setIcon)
        }

        let status = jointAccountModelEditor.status ?? status
        let members = jointAccountModelEditor.members ?? members
        let invites = jointAccountModelEditor.invites ?? invites
        let hasChanges = self.status != status || self.members != members || self.invites != invites

        guard hasChanges else {
            return self
        }

        self.status = status
        self.members = members
        self.invites = invites
        didChangeSubject.send()

        return self
    }
}

// MARK: - Identifiable protocol conformance

extension CommonJointAccountModel: Identifiable {
    var id: CryptoAccountModelId {
        cryptoAccount.id
    }
}

// MARK: - JointAccountModel protocol conformance

extension CommonJointAccountModel: JointAccountModel {
    var name: String {
        cryptoAccount.name
    }

    var icon: AccountModel.CompositeIcon {
        cryptoAccount.icon
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        cryptoAccount
            .didChangePublisher
            .merge(with: didChangeSubject)
            .eraseToAnyPublisher()
    }

    var isMainAccount: Bool {
        cryptoAccount.isMainAccount
    }

    var accountType: AccountType {
        cryptoAccount.accountType
    }

    var descriptionString: String {
        cryptoAccount.descriptionString
    }

    var walletModelsManager: WalletModelsManager {
        cryptoAccount.walletModelsManager
    }

    var userTokensManager: UserTokensManager {
        cryptoAccount.userTokensManager
    }

    func analyticsParameters(with builder: AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        cryptoAccount.analyticsParameters(with: builder)
    }

    @discardableResult
    func edit(with editor: (_ editor: CommonJointAccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        throw .unknownError(JointAccountModelError.editingNotSupported)
    }

    func archive() async throws(AccountArchivationError) {
        try await cryptoAccount.archive()
    }
}

// MARK: - BalanceProvidingAccountModel protocol conformance

extension CommonJointAccountModel: BalanceProvidingAccountModel {
    var fiatTotalBalanceProvider: AccountBalanceProvider {
        cryptoAccount.fiatTotalBalanceProvider
    }

    var rateProvider: AccountRateProvider {
        cryptoAccount.rateProvider
    }
}

// MARK: - DisposableEntity protocol conformance

extension CommonJointAccountModel: DisposableEntity {
    nonisolated func dispose() {
        cryptoAccount.dispose()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonJointAccountModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "cryptoAccount": cryptoAccount,
                "membersCount": policy.membersCount,
                "signersCount": policy.signersCount,
                "status": status,
                "Taken slots count": members.count,
                "Invites count": invites.count,
            ]
        )
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountModel {
    /// Not private: a private type cannot be the witness for `Editor`.
    final class CommonJointAccountModelEditor: JointAccountModelEditor {
        var name: String?
        var icon: AccountModel.CompositeIcon?
        var status: JointAccountStatus?
        var members: [JointAccountMember]?
        var invites: [JointAccountInvite]?

        func setName(_ name: String) {
            self.name = name
        }

        func setIcon(_ icon: AccountModel.CompositeIcon) {
            self.icon = icon
        }

        func setStatus(_ status: JointAccountStatus) {
            self.status = status
        }

        func setMembers(_ members: [JointAccountMember]) {
            self.members = members
        }

        func setInvites(_ invites: [JointAccountInvite]) {
            self.invites = invites
        }
    }
}
