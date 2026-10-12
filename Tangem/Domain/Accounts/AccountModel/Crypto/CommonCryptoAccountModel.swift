//
//  CommonCryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

final class CommonCryptoAccountModel {
    let walletModelsManager: WalletModelsManager
    let userTokensManager: UserTokensManager
    let accountBalanceProvider: AccountBalanceProvider
    let accountRateProvider: AccountRateProvider

    private(set) var icon: AccountModel.CompositeIcon {
        didSet {
            if oldValue != icon {
                didChangeSubject.send()
            }
        }
    }

    var name: String {
        if let name = _name?.nilIfEmpty {
            return name
        }
        if isMainAccount {
            return Localization.accountMainAccountTitle
        }

        return .empty
    }

    private var _name: String? {
        didSet {
            if oldValue != _name {
                didChangeSubject.send()
            }
        }
    }

    private let didChangeSubject = PassthroughSubject<Void, Never>()
    private let accountId: AccountId
    private let derivationIdentity: CryptoAccountDerivationIdentity
    private weak var delegate: CommonCryptoAccountModelDelegate?

    /// - Warning: The derivation manager is not used directly in this class, but a strong reference is stored here
    /// to keep it alive, since there is a circular dependency between `DerivationManager` and `UserTokensManager`,
    /// therefore `UserTokensManager` has only a weak reference to it.
    private let derivationManager: DerivationManager?

    /// Designated initializer.
    /// - Note: `name` argument can be nil for main accounts, in this case a default localized name will be used.
    init(
        userWalletId: UserWalletId,
        accountName: String?,
        accountIcon: AccountModel.CompositeIcon,
        derivationIdentity: CryptoAccountDerivationIdentity,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        accountBalanceProvider: AccountBalanceProvider,
        accountRateProvider: AccountRateProvider,
        derivationManager: DerivationManager?,
        delegate: CommonCryptoAccountModelDelegate
    ) {
        let accountId = AccountId(userWalletId: userWalletId, derivationIdentity: derivationIdentity)

        self.accountId = accountId
        _name = accountName
        icon = accountIcon
        self.derivationIdentity = derivationIdentity
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.accountBalanceProvider = accountBalanceProvider
        self.accountRateProvider = accountRateProvider
        self.derivationManager = derivationManager
        self.delegate = delegate
    }
}

// MARK: - AccountModelEditable protocol conformance

extension CommonCryptoAccountModel {
    /// Updates the model properties directly without involving the delegate (internal use only by the account model registries).
    @discardableResult
    func update(with editor: (_ editor: CommonAccountModelEditor) -> Void) -> Self {
        let accountModelEditor = CommonAccountModelEditor()
        editor(accountModelEditor)

        if let newName = accountModelEditor.name {
            _name = newName
        }

        if let newIcon = accountModelEditor.icon {
            icon = newIcon
        }

        return self
    }
}

// MARK: - Identifiable protocol conformance

extension CommonCryptoAccountModel: Identifiable {
    var id: AccountId {
        accountId
    }
}

// MARK: - CryptoAccountModel protocol conformance

extension CommonCryptoAccountModel: CryptoAccountModel {
    var isMainAccount: Bool {
        AccountModelUtils.isMainAccount(derivationIdentity)
    }

    var accountType: AccountType {
        derivationIdentity.type
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    var descriptionString: String {
        Localization.accountFormAccountIndex(derivationIdentity.derivationIndex)
    }

    // MARK: - AccountModelAnalyticsProviding

    func analyticsParameters(with builder: AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        builder
            .setDerivationIdentity(derivationIdentity)
            .build()
    }

    /// Edits the account model using the provided editor closure (external use by consumers).
    @discardableResult
    func edit(with editor: (_ editor: CommonAccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        let accountModelEditor = CommonAccountModelEditor()
        editor(accountModelEditor)

        guard accountModelEditor.hasChanges, let delegate else {
            return self
        }

        let persistentConfig = CryptoAccountPersistentConfig(
            derivationIdentity: derivationIdentity,
            name: accountModelEditor.name ?? _name,
            icon: accountModelEditor.icon ?? icon
        )

        try await delegate.commonCryptoAccountModel(self, wantsToUpdateWith: persistentConfig)

        return self
    }

    func archive() async throws(AccountArchivationError) {
        guard let delegate else {
            return
        }

        try await delegate.commonCryptoAccountModelWantsToArchive(self)
    }
}

// MARK: - BalanceProvidingAccountModel protocol conformance

extension CommonCryptoAccountModel: BalanceProvidingAccountModel {
    var fiatTotalBalanceProvider: AccountBalanceProvider {
        accountBalanceProvider
    }

    var rateProvider: AccountRateProvider {
        accountRateProvider
    }
}

// MARK: - DisposableEntity protocol conformance

extension CommonCryptoAccountModel: DisposableEntity {
    nonisolated func dispose() {
        walletModelsManager.dispose()
        userTokensManager.dispose()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonCryptoAccountModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": name,
                "icon": icon,
                "id": id,
                "derivationIdentity": derivationIdentity,
                "User tokens count": userTokensManager.userTokens.count,
                "Wallet models count": walletModelsManager.walletModels.count,
            ]
        )
    }
}

// MARK: - Auxiliary types

extension CommonCryptoAccountModel {
    /// Not private: a private type cannot be the witness for `Editor`.
    final class CommonAccountModelEditor: AccountModelEditor {
        var name: String?
        var icon: AccountModel.CompositeIcon?

        var hasChanges: Bool {
            return name != nil || icon != nil
        }

        func setName(_ name: String) {
            self.name = name
        }

        func setIcon(_ icon: AccountModel.CompositeIcon) {
            self.icon = icon
        }
    }
}
