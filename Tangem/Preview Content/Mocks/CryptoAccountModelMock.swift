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
import TangemNFT

final class CryptoAccountModelMock {
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

    init(
        isMainAccount: Bool,
        walletModelsManager: WalletModelsManager = WalletModelsManagerMock(),
        totalBalanceProvider: TotalBalanceProvider = TotalBalanceProviderMock(),
        userTokensManager: UserTokensManager = UserTokensManagerMock()
    ) {
        self.isMainAccount = isMainAccount
        self.walletModelsManager = walletModelsManager
        self.totalBalanceProvider = totalBalanceProvider
        self.userTokensManager = userTokensManager
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

    func setName(_ name: String) {
        self.name = name
    }

    func setIcon(_ icon: AccountModel.Icon) {
        self.icon = icon
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
