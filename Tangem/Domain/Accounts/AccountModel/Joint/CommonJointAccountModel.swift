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
    private var accountStatus: JointAccountStatus {
        didSet { didChangeSubject.send() }
    }

    private let derivationIdentity: CryptoAccountDerivationIdentity
    private let accountPolicy: JointAccountPolicy
    private let cryptoAccount: any CryptoAccountModel
    private let operationsService: any JointAccountOperationsService
    private let pendingOperationsProvider: any JointAccountPendingOperationsProvider
    private let membersService: any JointAccountMembersService
    private weak var delegate: (any JointAccountModelDelegate)?

    private let didChangeSubject = PassthroughSubject<Void, Never>()

    init(
        cryptoAccount: any CryptoAccountModel,
        derivationIdentity: CryptoAccountDerivationIdentity,
        accountPolicy: JointAccountPolicy,
        accountStatus: JointAccountStatus,
        operationsService: any JointAccountOperationsService,
        pendingOperationsProvider: any JointAccountPendingOperationsProvider,
        membersService: any JointAccountMembersService,
        delegate: any JointAccountModelDelegate
    ) {
        self.cryptoAccount = cryptoAccount
        self.derivationIdentity = derivationIdentity
        self.accountPolicy = accountPolicy
        self.accountStatus = accountStatus
        self.operationsService = operationsService
        self.pendingOperationsProvider = pendingOperationsProvider
        self.membersService = membersService
        self.delegate = delegate
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

        if let newStatus = jointAccountModelEditor.status, accountStatus != newStatus {
            accountStatus = newStatus
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

    var status: JointAccountStatus {
        accountStatus
    }

    var canActivate: Bool {
        guard case .confirming = accountStatus else {
            return false
        }

        return membersService.userRole.isCreator
    }

    func activate() async throws(AccountEditError) {
        guard let delegate else {
            let error = JointAccountModelError.activationUnavailable
            JointAccountsLogger.error("The joint account has nothing left to activate it", error: error)
            throw .unknownError(error)
        }

        let config = try makeActivationConfig()
        try await delegate.activateJointAccount(with: config)
    }
}

// MARK: - CryptoAccountModel protocol conformance

extension CommonJointAccountModel: CryptoAccountModel {
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

// MARK: - Private

private extension CommonJointAccountModel {
    /// Checked before the wallet is asked for anything: a composition that does not resolve to the announced address
    /// is not the account it claims to be, and there is nothing worth signing.
    func makeActivationConfig() throws(AccountEditError) -> JointAccountActivationConfig {
        // Announced, not verified: the address is the backend's word until the composition is checked against it.
        // Read before the composition is, so that an account that cannot be activated costs nothing to turn away
        guard case .confirming(.some(let announcedSafeAddress)) = status else {
            throw .unknownError(JointAccountModelError.notReadyForActivation)
        }

        let members = membersService.slots.compactMap(\.member)

        guard let creator = members.first(where: { $0.role == .creator }) else {
            throw .unknownError(JointAccountModelError.notReadyForActivation)
        }

        let safeAddress: String

        do {
            safeAddress = try JointAccountSafeAddressVerifier.confirm(
                announcedAddress: announcedSafeAddress,
                owners: members.map(\.address),
                threshold: accountPolicy.signersCount
            )
        } catch {
            JointAccountsLogger.error("The joint account does not resolve to the address it was given", error: error)
            throw .unknownError(error)
        }

        return JointAccountActivationConfig(
            // The identifier the backend minted the account with is the one the app works out for itself, case included
            cryptoAccountId: id.rawValue.hexString,
            signedConfig: JointAccountSignedConfig(
                name: name,
                icon: icon.name.rawValue,
                iconColor: icon.color.rawValue,
                membersCount: accountPolicy.membersCount,
                threshold: accountPolicy.signersCount
            ),
            safeAddress: safeAddress,
            creatorAddress: creator.address,
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
        objectDescription(self, userInfo: [
            "cryptoAccount": cryptoAccount,
            "accountPolicy": accountPolicy,
            "status": status,
        ])
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountModel {
    /// Not private: a private type cannot be the witness for `Editor`.
    final class CommonJointAccountModelEditor: JointAccountModelEditor {
        var name: String?
        var icon: AccountModel.CompositeIcon?
        var status: JointAccountStatus?

        func setName(_ name: String) {
            self.name = name
        }

        func setIcon(_ icon: AccountModel.CompositeIcon) {
            self.icon = icon
        }

        func setStatus(_ status: JointAccountStatus) {
            self.status = status
        }
    }
}
