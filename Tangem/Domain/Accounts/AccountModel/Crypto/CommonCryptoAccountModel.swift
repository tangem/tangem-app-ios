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

    private(set) var icon: AccountModel.Icon {
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
    private let derivationIndex: Int
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
        accountIcon: AccountModel.Icon,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        accountBalanceProvider: AccountBalanceProvider,
        accountRateProvider: AccountRateProvider,
        derivationManager: DerivationManager?,
        delegate: CommonCryptoAccountModelDelegate
    ) {
        let accountId = AccountId(userWalletId: userWalletId, derivationIndex: derivationIndex)

        self.accountId = accountId
        _name = accountName
        icon = accountIcon
        self.derivationIndex = derivationIndex
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.accountBalanceProvider = accountBalanceProvider
        self.accountRateProvider = accountRateProvider
        self.derivationManager = derivationManager
        self.delegate = delegate
    }

    /// Updates the model properties directly without involving the delegate (internal use only by `AccountModelsManager`).
    @discardableResult
    func update(with editor: Editor) -> Self {
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
        AccountModelUtils.isMainAccount(derivationIndex)
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    var descriptionString: String {
        Localization.accountFormAccountIndex(derivationIndex)
    }

    // MARK: - AccountModelAnalyticsProviding

    func analyticsParameters(with builder: AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        builder
            .setDerivationIndex(derivationIndex)
            .build()
    }

    /// Edits the account model using the provided editor closure (external use by consumers).
    @discardableResult
    func edit(with editor: Editor) async throws(AccountEditError) -> Self {
        let accountModelEditor = CommonAccountModelEditor()
        editor(accountModelEditor)

        guard accountModelEditor.hasChanges, let delegate else {
            return self
        }

        let persistentConfig = CryptoAccountPersistentConfig(
            derivationIndex: derivationIndex,
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

// MARK: - CustomStringConvertible protocol conformance

extension CommonCryptoAccountModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": name,
                "icon": icon,
                "id": id,
                "derivationIndex": derivationIndex,
                "User tokens count": userTokensManager.userTokens.count,
                "Wallet models count": walletModelsManager.walletModels.count,
            ]
        )
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountModel {
    final class CommonAccountModelEditor: AccountModelEditor {
        var name: String?
        var icon: AccountModel.Icon?

        var hasChanges: Bool {
            return name != nil || icon != nil
        }

        func setName(_ name: String) {
            self.name = name
        }

        func setIcon(_ icon: AccountModel.Icon) {
            self.icon = icon
        }
    }
}
