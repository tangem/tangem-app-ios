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

    /// Designated initializer.
    /// - Note: `name` argument can be nil for main accounts, in this case a default localized name will be used.
    init(
        accountId: AccountId,
        accountName: String?,
        accountIcon: AccountModel.Icon,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager
    ) {
        self.accountId = accountId
        _name = accountName
        icon = accountIcon
        self.derivationIndex = derivationIndex
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
    }
}

// MARK: - Convenience extensions

extension CommonCryptoAccountModel {
    /// Convenience init, initializes a `CommonCryptoAccountModel` with a `UserWalletId` and a derivation index.
    /// - Note: `name` argument can be nil for main accounts, in this case a default localized name will be used.
    convenience init(
        userWalletId: UserWalletId,
        accountName: String?,
        accountIcon: AccountModel.Icon,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
    ) {
        let accountId = AccountId(userWalletId: userWalletId, derivationIndex: derivationIndex)
        self.init(
            accountId: accountId,
            accountName: accountName,
            accountIcon: accountIcon,
            derivationIndex: derivationIndex,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager
        )
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

    var userTokenListManager: UserTokenListManager {
        // [REDACTED_TODO_COMMENT]
        fatalError()
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
        // [REDACTED_TODO_COMMENT]
        fatalError("\(#function) not implemented yet!")
    }

    var rateProvider: AccountRateProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError("\(#function) not implemented yet!")
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
            ]
        )
    }
}
