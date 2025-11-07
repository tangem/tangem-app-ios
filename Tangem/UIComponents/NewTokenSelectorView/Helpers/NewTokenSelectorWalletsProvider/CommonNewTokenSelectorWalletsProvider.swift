//
//  CommonNewTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

class CommonNewTokenSelectorWalletsProvider: NewTokenSelectorWalletsProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let availabilityProviderFactory: any NewTokenSelectorItemAvailabilityProviderFactory

    init(availabilityProviderFactory: any NewTokenSelectorItemAvailabilityProviderFactory) {
        self.availabilityProviderFactory = availabilityProviderFactory
    }

    var walletsPublisher: AnyPublisher<[NewTokenSelectorWallet], Never> {
        Just(userWalletRepository.models)
            .withWeakCaptureOf(self)
            .map { provider, userWalletModels in
                userWalletModels.map { userWalletModel in
                    provider.mapToNewTokenSelectorWallet(userWalletModel: userWalletModel)
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Mapping

    func mapToNewTokenSelectorWallet(userWalletModel: any UserWalletModel) -> NewTokenSelectorWallet {
        let accountsPublisher = userWalletModel.accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .compactMap { provider, accountModels -> NewTokenSelectorWallet.AccountType? in
                guard let cryptoAccountModel = accountModels.standard() else {
                    assertionFailure("UserWalletModel does not contain CryptoAccount")
                    return nil
                }

                switch cryptoAccountModel {
                case .standard(.single(let account)):
                    return .single(
                        provider.mapToNewTokenSelectorAccount(wallet: userWalletModel, cryptoAccount: account)
                    )
                case .standard(.multiple(let accounts)):
                    return .multiple(accounts.map {
                        provider.mapToNewTokenSelectorAccount(wallet: userWalletModel, cryptoAccount: $0)
                    })
                }
            }
            .eraseToAnyPublisher()

        return NewTokenSelectorWallet(wallet: userWalletModel.userWalletInfo, accountsPublisher: accountsPublisher)
    }

    func mapToNewTokenSelectorAccount(wallet: any UserWalletModel, cryptoAccount: any CryptoAccountModel) -> NewTokenSelectorAccount {
        let selectorWallet = NewTokenSelectorItem.Wallet(userWalletInfo: wallet.userWalletInfo)
        let iconViewData = AccountIconViewBuilder.makeAccountIconViewData(accountModel: cryptoAccount)
        let selectorAccount = NewTokenSelectorItem.Account(name: cryptoAccount.name, icon: iconViewData)

        let adapter = TokenSectionsAdapter(
            userTokensManager: cryptoAccount.userTokensManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: cryptoAccount.userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let tokenSectionsSourcePublisher = sourcePublisherFactory.makeSourcePublisher(for: cryptoAccount)

        let itemsPublisher = adapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: .global())
            .map { section -> [any WalletModel] in
                section.flatMap { $0.items.compactMap { $0.walletModel } }
            }
            .withWeakCaptureOf(self)
            .map { provider, walletModels in
                withExtendedLifetime(adapter) {}

                return walletModels.map { walletModel in
                    provider.mapToNewTokenSelectorItem(
                        selectorWallet: selectorWallet, selectorAccount: selectorAccount, walletModel: walletModel
                    )
                }
            }
            .eraseToAnyPublisher()

        return NewTokenSelectorAccount(account: selectorAccount, itemsPublisher: itemsPublisher)
    }

    func mapToNewTokenSelectorItem(
        selectorWallet: NewTokenSelectorItem.Wallet,
        selectorAccount: NewTokenSelectorItem.Account,
        walletModel: any WalletModel
    ) -> NewTokenSelectorItem {
        NewTokenSelectorItem(
            wallet: selectorWallet,
            account: selectorAccount,
            availabilityProvider: availabilityProviderFactory.makeAvailabilityProvider(
                userWalletInfo: selectorWallet.userWalletInfo,
                walletModel: walletModel
            ),
            walletModel: walletModel
        )
    }
}
