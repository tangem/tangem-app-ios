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
import TangemNFT

final class CommonCryptoAccountModel {
    let walletModelsManager: WalletModelsManager
    let userTokensManager: UserTokensManager
    let accountBalanceProvider: AccountBalanceProvider
    let accountRateProvider: AccountRateProvider

    private unowned var _userWalletModel: UserWalletModel!

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

    /// - Warning: The derivation manager is not used directly in this class, but a strong reference is stored here
    /// to keep it alive, since there is a circular dependency between `DerivationManager` and `UserTokensManager`,
    /// therefore `UserTokensManager` has only a weak reference to it.
    private let derivationManager: DerivationManager?

    /// Designated initializer.
    /// - Note: `name` argument can be nil for main accounts, in this case a default localized name will be used.
    init(
        accountName: String?,
        accountIcon: AccountModel.Icon,
        derivationIndex: Int,
        userWalletModel: UserWalletModel,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        accountBalanceProvider: AccountBalanceProvider,
        accountRateProvider: AccountRateProvider,
        derivationManager: DerivationManager?
    ) {
        let accountId = AccountId(userWalletId: userWalletModel.userWalletId, derivationIndex: derivationIndex)

        self.accountId = accountId
        _name = accountName
        _userWalletModel = userWalletModel
        icon = accountIcon
        self.derivationIndex = derivationIndex
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.accountBalanceProvider = accountBalanceProvider
        self.accountRateProvider = accountRateProvider
        self.derivationManager = derivationManager
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

    var userWalletModel: any UserWalletModel {
        _userWalletModel
    }

    var descriptionString: String {
        Localization.accountFormAccountIndex(derivationIndex)
    }

    func setName(_ name: String) {
        _name = name
    }

    func setIcon(_ icon: AccountModel.Icon) {
        self.icon = icon
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

// MARK: - CryptoAccountPersistentConfigConvertible protocol conformance

extension CommonCryptoAccountModel: CryptoAccountPersistentConfigConvertible {
    func toPersistentConfig() -> CryptoAccountPersistentConfig {
        return CryptoAccountPersistentConfig(
            derivationIndex: derivationIndex,
            name: _name,
            icon: icon
        )
    }
}
