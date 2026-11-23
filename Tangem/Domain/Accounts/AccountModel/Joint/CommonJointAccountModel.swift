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
    private let derivationIdentity: CryptoAccountDerivationIdentity
    private let accountPolicy: JointAccountPolicy
    private let cryptoAccount: any CryptoAccountModel
    private let statusProvider: any JointAccountStatusProvider
    private let operationsService: any JointAccountOperationsService
    private let pendingOperationsProvider: any JointAccountPendingOperationsProvider
    private let membersService: any JointAccountMembersService
    private let finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater
    private let userRoleService: any JointAccountUserRoleService
    private weak var delegate: (any JointAccountModelDelegate)?

    init(
        cryptoAccount: any CryptoAccountModel,
        derivationIdentity: CryptoAccountDerivationIdentity,
        accountPolicy: JointAccountPolicy,
        statusProvider: any JointAccountStatusProvider,
        operationsService: any JointAccountOperationsService,
        pendingOperationsProvider: any JointAccountPendingOperationsProvider,
        membersService: any JointAccountMembersService,
        finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater,
        userRoleService: any JointAccountUserRoleService,
        delegate: any JointAccountModelDelegate
    ) {
        self.cryptoAccount = cryptoAccount
        self.derivationIdentity = derivationIdentity
        self.accountPolicy = accountPolicy
        self.statusProvider = statusProvider
        self.operationsService = operationsService
        self.pendingOperationsProvider = pendingOperationsProvider
        self.membersService = membersService
        self.finishedOperationsWalletUpdater = finishedOperationsWalletUpdater
        self.userRoleService = userRoleService
        self.delegate = delegate
    }
}

// MARK: - AccountModelEditable protocol conformance

extension CommonJointAccountModel {
    @discardableResult
    func update(with editor: (_ editor: CommonCryptoAccountModel.CommonAccountModelEditor) -> Void) -> Self {
        let accountModelEditor = CommonCryptoAccountModel.CommonAccountModelEditor()
        editor(accountModelEditor)

        cryptoAccount.update { cryptoAccountModelEditor in
            accountModelEditor.name.map(cryptoAccountModelEditor.setName)
            accountModelEditor.icon.map(cryptoAccountModelEditor.setIcon)
        }

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
    var policy: JointAccountPolicy {
        accountPolicy
    }

    var jointAccountStatusProvider: any JointAccountStatusProvider {
        statusProvider
    }

    @discardableResult
    func confirm(safeAddress: String) async throws(AccountEditError) -> JointAccountStatus {
        guard let delegate else {
            let error = JointAccountModelError.confirmationUnavailable
            JointAccountsLogger.error("The joint account has nothing left to confirm it", error: error)
            throw .unknownError(error)
        }

        let config = try makeConfirmationConfig(safeAddress: safeAddress)
        return try await delegate.confirmJointAccount(with: config)
    }

    var name: String {
        cryptoAccount.name
    }

    var icon: AccountModel.CompositeIcon {
        cryptoAccount.icon
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        cryptoAccount
            .didChangePublisher
            .merge(with: statusProvider.statusPublisher.dropFirst().map { _ in () })
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

    var pendingDerivationProvider: AccountPendingDerivationProvider {
        cryptoAccount.pendingDerivationProvider
    }

    func analyticsParameters(with builder: AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        cryptoAccount.analyticsParameters(with: builder)
    }

    @discardableResult
    func edit(with editor: (_ editor: CommonCryptoAccountModel.CommonAccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        throw .unknownError(JointAccountModelError.editingNotSupported)
    }

    func archive() async throws(AccountArchivationError) {
        try await cryptoAccount.archive()
    }
}

// MARK: - AccountModelResolvable protocol conformance

extension CommonJointAccountModel {
    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}

// MARK: - Private

private extension CommonJointAccountModel {
    func makeConfirmationConfig(safeAddress: String) throws(AccountEditError) -> JointAccountConfirmationConfig {
        guard case .confirming(.some(let statusSafeAddress)) = statusProvider.status else {
            throw .unknownError(JointAccountModelError.notReadyForConfirmation)
        }

        guard statusSafeAddress == safeAddress else {
            throw .unknownError(JointAccountModelError.addressChanged)
        }

        return JointAccountConfirmationConfig(
            signedConfig: JointAccountSignedConfig(
                name: name,
                icon: icon.name.rawValue,
                iconColor: icon.color.rawValue,
                membersCount: accountPolicy.membersCount,
                threshold: accountPolicy.signersCount
            ),
            safeAddress: safeAddress,
            derivationIndex: derivationIdentity.derivationIndex
        )
    }
}

// MARK: - JointAccountOperationsServicesProviding protocol conformance

extension CommonJointAccountModel: JointAccountOperationsServicesProviding {
    var jointAccountOperationsService: any JointAccountOperationsService {
        operationsService
    }

    var jointAccountPendingOperationsProvider: any JointAccountPendingOperationsProvider {
        pendingOperationsProvider
    }
}

// MARK: - JointAccountMembersServiceProviding protocol conformance

extension CommonJointAccountModel: JointAccountMembersServiceProviding {
    var jointAccountMembersService: any JointAccountMembersService {
        membersService
    }

    var jointAccountUserRoleService: any JointAccountUserRoleService {
        userRoleService
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
        finishedOperationsWalletUpdater.dispose()
        cryptoAccount.dispose()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonJointAccountModel: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: [
            "cryptoAccount": cryptoAccount,
            "accountPolicy": accountPolicy,
            "status": statusProvider.status,
        ])
    }
}
