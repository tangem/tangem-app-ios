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
    let jointAccountConfig: JointAccountConfig
    let members: [JointAccountMember]
    let invites: [JointAccountInvite]

    private let cryptoAccount: any CryptoAccountModel

    init(
        cryptoAccount: any CryptoAccountModel,
        jointAccountConfig: JointAccountConfig,
        members: [JointAccountMember],
        invites: [JointAccountInvite]
    ) {
        self.cryptoAccount = cryptoAccount
        self.jointAccountConfig = jointAccountConfig
        self.members = members
        self.invites = invites
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
        cryptoAccount.didChangePublisher
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
    func edit(with editor: Editor) async throws(AccountEditError) -> Self {
        try await cryptoAccount.edit(with: editor)

        return self
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
                "membersCount": jointAccountConfig.membersCount,
                "signersCount": jointAccountConfig.signersCount,
                "status": jointAccountConfig.status,
                "Taken slots count": members.count,
                "Invites count": invites.count,
            ]
        )
    }
}
