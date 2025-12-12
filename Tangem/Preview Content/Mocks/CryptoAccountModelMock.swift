//
//  CryptoAccountModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

final class CryptoAccountModelMock {
    typealias OnArchive = (_ cryptoAccountModel: CryptoAccountModelMock) -> Void

    let id = AccountId()
    let isMainAccount: Bool
    let walletModelsManager: WalletModelsManager
    let totalBalanceProvider: TotalBalanceProvider
    let userTokensManager: UserTokensManager

    private(set) var name = "Mock Account" {
        didSet {
            if oldValue != name {
                didChangeSubject.send()
            }
        }
    }

    private(set) var icon = AccountModel.Icon(
        name: .allCases.randomElement()!,
        color: .allCases.randomElement()!
    ) {
        didSet {
            if oldValue != icon {
                didChangeSubject.send()
            }
        }
    }

    private let didChangeSubject = PassthroughSubject<Void, Never>()
    private let onArchive: OnArchive

    init(
        isMainAccount: Bool,
        walletModelsManager: WalletModelsManager = WalletModelsManagerMock(),
        totalBalanceProvider: TotalBalanceProvider = TotalBalanceProviderMock(),
        userTokensManager: UserTokensManager = UserTokensManagerMock(),
        onArchive: @escaping OnArchive
    ) {
        self.isMainAccount = isMainAccount
        self.walletModelsManager = walletModelsManager
        self.totalBalanceProvider = totalBalanceProvider
        self.userTokensManager = userTokensManager
        self.onArchive = onArchive
    }
}

// MARK: - Auxiliary types

extension CryptoAccountModelMock {
    struct AccountId: Hashable, AccountModelPersistentIdentifierConvertible {
        let id = UUID()

        var isMainAccount: Bool {
            false
        }

        func toPersistentIdentifier() -> UUID {
            id
        }
    }

    private struct AccountRateProviderStub: AccountRateProvider {
        var accountRate: AccountRate {
            return .loaded(
                quote: AccountQuote(priceChange24h: Decimal(stringValue: "1.23")!)
            )
        }

        var accountRatePublisher: AnyPublisher<AccountRate, Never> {
            .just(output: accountRate)
        }
    }
}

// MARK: - CryptoAccountModel protocol conformance

extension CryptoAccountModelMock: CryptoAccountModel {
    var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    var descriptionString: String {
        Localization.accountFormAccountIndex(0)
    }

    var userWalletModel: any UserWalletModel {
        UserWalletModelMock()
    }

    @discardableResult
    func edit(with editor: Editor) async throws(AccountEditError) -> Self {
        let cryptoAccountModelMockEditor = CryptoAccountModelMockEditor(cryptoAccountModel: self)
        editor(cryptoAccountModelMockEditor)
        return self
    }

    func archive() async throws(AccountArchivationError) {
        onArchive(self)
    }
}

// MARK: - BalanceProvidingAccountModel protocol conformance

extension CryptoAccountModelMock: BalanceProvidingAccountModel {
    var fiatTotalBalanceProvider: AccountBalanceProvider {
        CommonAccountBalanceProvider(totalBalanceProvider: totalBalanceProvider)
    }

    var rateProvider: AccountRateProvider {
        AccountRateProviderStub()
    }
}

// MARK: - Auxiliary types

private extension CryptoAccountModelMock {
    struct CryptoAccountModelMockEditor: AccountModelEditor {
        let cryptoAccountModel: CryptoAccountModelMock

        func setName(_ name: String) {
            cryptoAccountModel.name = name
        }

        func setIcon(_ icon: AccountModel.Icon) {
            cryptoAccountModel.icon = icon
        }
    }
}
